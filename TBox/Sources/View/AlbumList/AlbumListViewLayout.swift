//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

protocol AlbumListViewEditing: AnyObject {
    func isEditing(_ layout: AlbumListViewLayout.Type) -> Bool
}

enum AlbumListViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case main
    }

    struct Item: Equatable, Hashable {
        let album: Album
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
                guard item.album.isHidden != cell.isHiddenAlbum else { return }
                cell.setAlbumHiding(item.album.isHidden, animated: true)
            }
        }
    }

    static func configureAlbumCell(thumbnailLoader: ThumbnailLoader,
                                   editing: AlbumListViewEditing,
                                   delegate: AlbumListCollectionViewCellDelegate) -> UICollectionView.CellRegistration<AlbumListCollectionViewCell, Item>
    {
        return .init(cellNib: AlbumListCollectionViewCell.nib) { [weak thumbnailLoader, weak editing, weak delegate] cell, indexPath, item in
            cell.title = item.album.title
            cell.clipCount = item.album.clips.count
            cell.setEditing(editing?.isEditing(Self.self) ?? false, animated: false)
            cell.delegate = delegate

            cell.setHiddenIconVisibility(true, animated: false)
            cell.setAlbumHiding(item.album.isHidden, animated: false)

            let requestId = UUID().uuidString
            cell.identifier = requestId

            if let thumbnailTarget = item.album.clips.first?.primaryItem {
                let info = ThumbnailRequest.ThumbnailInfo(id: "album-list-\(thumbnailTarget.identity.uuidString)",
                                                          size: cell.thumbnailSize,
                                                          scale: cell.traitCollection.displayScale)
                let imageRequest = ImageDataLoadRequest(imageId: thumbnailTarget.imageId)
                let request = ThumbnailRequest(requestId: requestId,
                                               originalImageRequest: imageRequest,
                                               thumbnailInfo: info)
                thumbnailLoader?.load(request: request, observer: cell)
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
                                    thumbnailLoader: ThumbnailLoader,
                                    editing: AlbumListViewEditing,
                                    delegate: AlbumListCollectionViewCellDelegate) -> DataSource
    {
        let albumCellRegistration = self.configureAlbumCell(thumbnailLoader: thumbnailLoader,
                                                            editing: editing,
                                                            delegate: delegate)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: item)
        }
    }
}
