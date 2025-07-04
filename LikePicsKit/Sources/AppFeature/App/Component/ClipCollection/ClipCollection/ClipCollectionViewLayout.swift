//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
import UIKit

enum ClipCollectionViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum LayoutRequest {
        case waterfall(ClipCollectionWaterfallLayoutDelegate)
        case grid
    }

    enum Section {
        case main
    }

    struct Item: Equatable, Hashable {
        var clip: Clip

        var id: UUID { clip.id }
        var isHidden: Bool { clip.isHidden }

        var primaryItem: ClipItem? { clip.primaryItem }
        var secondaryItem: ClipItem? { clip.secondaryItem }
        var tertiaryItem: ClipItem? { clip.tertiaryItem }

        init(_ clip: Clip) {
            self.clip = clip
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            // isHidden, updatedDate は差分更新に含めないよう、比較から外す
            return lhs.clip.id == rhs.clip.id
                && lhs.clip.description == rhs.clip.description
                && lhs.clip.items == rhs.clip.items
                && lhs.clip.dataSize == rhs.clip.dataSize
                && lhs.clip.registeredDate == rhs.clip.registeredDate
        }
    }
}

// MARK: - Layout

extension ClipCollectionViewLayout {
    static func createLayout(_ request: LayoutRequest) -> UICollectionViewLayout {
        switch request {
        case let .waterfall(delegate):
            return createWaterfallLayout(with: delegate)

        case .grid:
            return createGridLayout()
        }
    }

    // MARK: Waterfall

    private static func createWaterfallLayout(with delegate: ClipCollectionWaterfallLayoutDelegate) -> UICollectionViewLayout {
        let layout = ClipCollectionWaterfallLayout()
        layout.delegate = delegate
        return layout
    }

    // MARK: Grid

    private static func createGridLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return self.createSection(environment: environment)
        }
    }

    private static func createSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let count: Int = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return 2

            case .regular:
                return 4

            case .unspecified:
                return 2

            @unknown default:
                return 2
            }
        }()
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalWidth(1 / CGFloat(count))
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(16)
        section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)

        return section
    }
}

extension ClipCollection.Layout {
    func toRequest(delegate: ClipCollectionWaterfallLayoutDelegate) -> ClipCollectionViewLayout.LayoutRequest {
        switch self {
        case .waterfall:
            return .waterfall(delegate)

        case .grid:
            return .grid
        }
    }
}

// MARK: - DataSource

extension ClipCollectionViewLayout {
    @MainActor
    static func configureDataSource(
        store: ClipCollectionViewController.Store,
        collectionView: UICollectionView,
        thumbnailProcessingQueue: ImageProcessingQueue,
        imageQueryService: ImageQueryServiceProtocol
    ) -> DataSource {
        let cellRegistration = configureCell(store: store, thumbnailProcessingQueue: thumbnailProcessingQueue, imageQueryService: imageQueryService)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    @MainActor
    private static func configureCell(
        store: ClipCollectionViewController.Store,
        thumbnailProcessingQueue: ImageProcessingQueue,
        imageQueryService: ImageQueryServiceProtocol
    ) -> UICollectionView.CellRegistration<ClipCollectionViewCell, Item> {
        return .init(cellNib: ClipCollectionViewCell.nib) { [weak store, weak thumbnailProcessingQueue, weak imageQueryService] cell, _, clip in
            cell.sizeDescription = .make(by: clip.clip)
            cell.isEditing = store?.stateValue.isEditing ?? false
            cell.setThumbnailType(toSingle: store?.stateValue.layout.isSingleThumbnail ?? false)

            cell.setHiddenIconVisibility(true, animated: false)
            cell.setClipHiding(clip.isHidden, animated: false)

            guard let processingQueue = thumbnailProcessingQueue,
                let imageQueryService = imageQueryService
            else { return }

            if let item = clip.primaryItem {
                loadThumbnail(item: item, processingQueue: processingQueue, thumbnailView: cell.primaryThumbnailView, imageQueryService: imageQueryService)

                let request = makeRequest(item: item, view: cell.primaryThumbnailView, imageQueryService: imageQueryService)
                cell.singleThumbnailView.smt.loadImage(request, with: processingQueue)
            } else {
                cancelLoadImage(on: cell.primaryThumbnailView)

                cell.singleThumbnailView.smt.cancelLoadImage()
            }

            if let item = clip.secondaryItem {
                loadThumbnail(item: item, processingQueue: processingQueue, thumbnailView: cell.secondaryThumbnailView, imageQueryService: imageQueryService)
            } else {
                cancelLoadImage(on: cell.secondaryThumbnailView)
            }

            if let item = clip.tertiaryItem {
                loadThumbnail(item: item, processingQueue: processingQueue, thumbnailView: cell.tertiaryThumbnailView, imageQueryService: imageQueryService)
            } else {
                cancelLoadImage(on: cell.tertiaryThumbnailView)
            }
        }
    }

    @MainActor
    private static func loadThumbnail(
        item: ClipItem,
        processingQueue: ImageProcessingQueue,
        thumbnailView: ClipCollectionThumbnailView,
        imageQueryService: ImageQueryServiceProtocol
    ) {
        let scale = thumbnailView.traitCollection.displayScale
        let size = thumbnailView.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
        // - SeeAlso: PreviewLoader
        let request = ImageRequest(resize: .init(size: size, scale: scale), cacheKey: "clip-collection-\(item.identity.uuidString)") { [imageQueryService, item] in
            try? imageQueryService.read(having: item.imageId)
        }

        loadImage(request, with: processingQueue, on: thumbnailView) { [weak processingQueue] response in
            guard let response = response, let diskCacheSize = response.diskCacheImageSize else { return }
            let shouldInvalidate = ThumbnailInvalidationChecker.shouldInvalidate(
                originalImageSizeInPoint: item.imageSize.cgSize,
                thumbnailSizeInPoint: size,
                diskCacheSizeInPixel: diskCacheSize,
                displayScale: scale
            )
            guard shouldInvalidate else { return }
            processingQueue?.config.diskCache?.remove(forKey: request.cacheKey)
            processingQueue?.config.memoryCache.remove(forKey: request.cacheKey)
        }
        thumbnailView.processingQueue = processingQueue
    }

    @MainActor
    private static func makeRequest(item: ClipItem, view: ClipCollectionThumbnailView, imageQueryService: ImageQueryServiceProtocol) -> ImageRequest {
        let scale = view.traitCollection.displayScale
        let size = view.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
        // - SeeAlso: PreviewLoader
        return ImageRequest(resize: .init(size: size, scale: scale), cacheKey: "clip-collection-\(item.identity.uuidString)") { [imageQueryService, item] in
            try? imageQueryService.read(having: item.imageId)
        }
    }
}

extension ClipCollectionViewCellSizeDescription {
    static func make(by clip: Clip) -> Self {
        return .init(
            primaryThumbnailSize: clip.primaryItem?.imageSize.cgSize ?? CGSize(width: 100, height: 100),
            secondaryThumbnailSize: clip.secondaryItem?.imageSize.cgSize,
            tertiaryThumbnailSize: clip.tertiaryItem?.imageSize.cgSize
        )
    }
}

extension UICollectionView {
    fileprivate var layout: ClipCollection.Layout {
        switch collectionViewLayout {
        case is ClipCollectionWaterfallLayout:
            return .waterfall

        default:
            return .grid
        }
    }
}
