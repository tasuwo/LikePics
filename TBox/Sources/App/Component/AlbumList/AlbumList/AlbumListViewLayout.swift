//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

enum AlbumListViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case main
    }

    struct Item: Equatable, Hashable {
        let album: Album
        let isEditing: Bool

        // MARK: - Equatable

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.album == rhs.album
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(album)
        }
    }
}

// MARK: - Layout

extension AlbumListViewLayout {
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

extension AlbumListViewLayout {
    static func apply(items: [Item], to dataSource: DataSource, in collectionView: UICollectionView) {
        var snapshot = Snapshot()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true) { [weak collectionView] in
            collectionView?.indexPathsForVisibleItems.forEach { indexPath in
                guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
                guard let cell = collectionView?.cellForItem(at: indexPath) as? AlbumListCollectionViewCell else { return }

                if item.album.isHidden != cell.isHiddenAlbum {
                    cell.setAlbumHiding(item.album.isHidden, animated: true)
                }
                if item.isEditing != cell.isEditing {
                    cell.setEditing(item.isEditing, animated: true)
                }
            }
        }
    }

    static func configureAlbumCell(thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable,
                                   delegate: AlbumListCollectionViewCellDelegate) -> UICollectionView.CellRegistration<AlbumListCollectionViewCell, Item>
    {
        return .init(cellNib: AlbumListCollectionViewCell.nib) { [weak thumbnailLoader, weak delegate] cell, _, item in
            cell.albumId = item.album.id
            cell.title = item.album.title
            cell.clipCount = item.album.clips.count
            cell.delegate = delegate

            cell.invalidator = thumbnailLoader

            cell.setEditing(item.isEditing, animated: false)

            cell.setHiddenIconVisibility(true, animated: false)
            cell.setAlbumHiding(item.album.isHidden, animated: false)

            let requestId = UUID().uuidString
            cell.identifier = requestId

            if let thumbnailTarget = item.album.clips.first?.primaryItem {
                let size = cell.calcThumbnailImageSize(originalSize: thumbnailTarget.imageSize.cgSize)
                let info = ThumbnailConfig(cacheKey: "album-list-\(thumbnailTarget.identity.uuidString)",
                                           size: size,
                                           scale: cell.traitCollection.displayScale)
                let imageRequest = ImageDataLoadRequest(imageId: thumbnailTarget.imageId)
                let request = ThumbnailRequest(requestId: requestId,
                                               originalImageRequest: imageRequest,
                                               config: info,
                                               userInfo: [.originalImageSize: thumbnailTarget.imageSize.cgSize])
                thumbnailLoader?.load(request, observer: cell)
                cell.onReuse = { identifier in
                    guard identifier == requestId else { return }
                    thumbnailLoader?.cancel(request)
                }
            } else {
                cell.thumbnail = nil
                cell.onReuse = nil
            }
        }
    }

    static func configureDataSource(collectionView: UICollectionView,
                                    thumbnailLoader: ThumbnailLoaderProtocol & ThumbnailInvalidatable,
                                    delegate: AlbumListCollectionViewCellDelegate) -> DataSource
    {
        let albumCellRegistration = self.configureAlbumCell(thumbnailLoader: thumbnailLoader, delegate: delegate)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: item)
        }
    }
}
