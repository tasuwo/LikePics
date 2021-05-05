//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

enum ClipCollectionViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

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
    static func createLayout(with delegate: ClipsCollectionLayoutDelegate) -> UICollectionViewLayout {
        let layout = ClipCollectionLayout()
        layout.delegate = delegate
        return layout
    }

    static func createGridLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return self.createSection(environment: environment)
        }
    }

    private static func createSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
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
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1 / CGFloat(count)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(16)
        section.contentInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)

        return section
    }
}

// MARK: - DataSource

extension ClipCollectionViewLayout {
    static func configureDataSource(collectionView: UICollectionView,
                                    thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable) -> DataSource
    {
        let cellRegistration = configureCell(collectionView: collectionView, thumbnailLoader: thumbnailLoader)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    private static func configureCell(collectionView: UICollectionView,
                                      thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable) -> UICollectionView.CellRegistration<ClipCollectionViewCell, Item>
    {
        return .init(cellNib: ClipCollectionViewCell.nib) { [weak collectionView, weak thumbnailLoader] cell, _, clip in
            cell.resetContent()

            let requestId = UUID().uuidString

            cell.identifier = requestId
            cell.invalidator = thumbnailLoader

            cell.sizeDescription = .make(by: clip.clip)
            cell.isEditing = collectionView?.isEditing ?? false
            cell.setThumbnailType(toSingle: collectionView?.isEditing ?? false)

            cell.setHiddenIconVisibility(true, animated: false)
            cell.setClipHiding(clip.isHidden, animated: false)

            let scale = cell.traitCollection.displayScale
            var requests: [ThumbnailRequest] = []

            if let item = clip.primaryItem {
                let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
                requests.append(self.makeRequest(for: item, id: requestId, size: size, scale: scale, context: .primary))
            }
            if let item = clip.secondaryItem {
                let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
                requests.append(self.makeRequest(for: item, id: requestId, size: size, scale: scale, context: .secondary))
            }
            if let item = clip.tertiaryItem {
                let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
                requests.append(self.makeRequest(for: item, id: requestId, size: size, scale: scale, context: .tertiary))
            }

            cell.onReuse = { [weak thumbnailLoader] identifier in
                guard identifier == requestId else { return }
                requests.forEach { thumbnailLoader?.cancel($0) }
            }

            requests.forEach { thumbnailLoader?.load($0, observer: cell) }
        }
    }

    private static func makeRequest(for item: ClipItem,
                                    id: String,
                                    size: CGSize,
                                    scale: CGFloat,
                                    context: ClipCollectionViewCell.ThumbnailOrder) -> ThumbnailRequest
    {
        // - SeeAlso: PreviewLoader
        let info = ThumbnailConfig(cacheKey: "clip-collection-\(item.identity.uuidString)",
                                   size: size,
                                   scale: scale)
        let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
        return ThumbnailRequest(requestId: id,
                                originalImageRequest: imageRequest,
                                config: info,
                                userInfo: [
                                    .clipThumbnailOrder: context.rawValue,
                                    .originalImageSize: item.imageSize.cgSize
                                ])
    }
}

extension ClipCollectionViewCellSizeDescription {
    static func make(by clip: Clip) -> Self {
        return .init(primaryThumbnailSize: clip.primaryItem?.imageSize.cgSize ?? CGSize(width: 100, height: 100),
                     secondaryThumbnailSize: clip.secondaryItem?.imageSize.cgSize,
                     tertiaryThumbnailSize: clip.tertiaryItem?.imageSize.cgSize)
    }
}
