//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
import UIKit

enum ClipItemListViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case main
    }

    struct Item: Equatable, Hashable {
        let itemId: UUID
        let imageId: UUID
        let imageFileName: String
        let imageSize: CGSize
        let imageDataSize: Int

        let order: Int
        let numberOfItems: Int

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.itemId == rhs.itemId
                && lhs.imageId == rhs.imageId
                && lhs.imageFileName == rhs.imageFileName
                && lhs.imageSize == rhs.imageSize
                && lhs.imageDataSize == rhs.imageDataSize
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(itemId)
            hasher.combine(imageId)
            hasher.combine(imageFileName)
            hasher.combine(NSCoder.string(for: imageSize).hashValue)
            hasher.combine(imageDataSize)
        }
    }
}

extension ClipItemListViewLayout.Item {
    init(_ item: ClipItem, at index: Int, of numberOfItems: Int) {
        itemId = item.id
        imageId = item.imageId
        imageFileName = item.imageFileName
        imageSize = item.imageSize.cgSize
        imageDataSize = item.imageDataSize

        order = index
        self.numberOfItems = numberOfItems
    }
}

// MARK: - Layout

extension ClipItemListViewLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, environment -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let count: Int = {
                switch environment.traitCollection.horizontalSizeClass {
                case .compact:
                    return 2

                case .regular, .unspecified:
                    return 4

                @unknown default:
                    return 4
                }
            }()
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
            group.interItemSpacing = .fixed(16)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = CGFloat(16)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

            return section
        }

        return layout
    }
}

// MARK: - DataSource

extension ClipItemListViewLayout {
    static func configureDataSource(_ collectionView: UICollectionView,
                                    _ thumbnailPipeline: Pipeline,
                                    _ imageQueryService: ImageQueryServiceProtocol) -> DataSource
    {
        let cellRegistration = configureCell(collectionView: collectionView,
                                             thumbnailPipeline: thumbnailPipeline,
                                             imageQueryService: imageQueryService)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    private static func configureCell(collectionView: UICollectionView,
                                      thumbnailPipeline: Pipeline,
                                      imageQueryService: ImageQueryServiceProtocol) -> UICollectionView.CellRegistration<ClipItemCell, Item>
    {
        return UICollectionView.CellRegistration<ClipItemCell, Item> { [weak thumbnailPipeline, weak imageQueryService] cell, _, item in
            var configuration = ClipItemContentConfiguration()
            configuration.fileName = item.imageFileName
            configuration.dataSize = item.imageDataSize
            configuration.page = item.order
            configuration.numberOfPage = item.numberOfItems
            cell.contentConfiguration = configuration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfiguration

            guard let pipeline = thumbnailPipeline,
                  let imageQueryService = imageQueryService
            else {
                return
            }

            let scale = cell.traitCollection.displayScale
            let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize)
            let provider = ImageDataProvider(imageId: item.imageId,
                                             cacheKey: "clip-info-\(item.itemId.uuidString)",
                                             imageQueryService: imageQueryService)
            let request = ImageRequest(source: .provider(provider),
                                       resize: .init(size: size, scale: scale))
            loadImage(request, with: pipeline, on: cell) { [weak pipeline] response in
                guard let response = response, let diskCacheSize = response.diskCacheImageSize else { return }
                let shouldInvalidate = ThumbnailInvalidationChecker.shouldInvalidate(originalImageSizeInPoint: item.imageSize,
                                                                                     thumbnailSizeInPoint: size,
                                                                                     diskCacheSizeInPixel: diskCacheSize,
                                                                                     displayScale: scale)
                guard shouldInvalidate else { return }
                pipeline?.config.diskCache?.remove(forKey: request.source.cacheKey)
                pipeline?.config.memoryCache.remove(forKey: request.source.cacheKey)
            }
        }
    }
}
