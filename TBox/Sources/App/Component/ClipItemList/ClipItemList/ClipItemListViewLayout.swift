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
                                    _ thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable) -> DataSource
    {
        let cellRegistration = configureCell(collectionView: collectionView, thumbnailLoader: thumbnailLoader)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    private static func configureCell(collectionView: UICollectionView,
                                      thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable) -> UICollectionView.CellRegistration<ClipItemCell, Item>
    {
        return UICollectionView.CellRegistration<ClipItemCell, Item> { [weak thumbnailLoader] cell, _, item in
            var configuration = ClipItemContentConfiguration()
            configuration.fileName = item.imageFileName
            configuration.dataSize = item.imageDataSize
            configuration.page = item.order
            configuration.numberOfPage = item.numberOfItems
            cell.contentConfiguration = configuration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfiguration

            let requestId = UUID().uuidString

            cell.identifier = requestId
            cell.invalidator = thumbnailLoader

            let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize)
            let info = ThumbnailConfig(cacheKey: "clip-info-\(item.itemId.uuidString)",
                                       size: size,
                                       scale: cell.traitCollection.displayScale)
            let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
            let request = ThumbnailRequest(requestId: requestId,
                                           originalImageRequest: imageRequest,
                                           config: info,
                                           userInfo: [
                                               .originalImageSize: item.imageSize
                                           ])
            cell.onReuse = { identifier in
                guard identifier == requestId else { return }
                thumbnailLoader?.cancel(request)
            }
            thumbnailLoader?.load(request, observer: cell)
        }
    }
}
