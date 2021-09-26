//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
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
            return lhs.album.id == rhs.album.id
                && lhs.album.title == rhs.album.title
                && lhs.album.clips == rhs.album.clips
        }

        // MARK: - Hashable

        func hash(into hasher: inout Hasher) {
            hasher.combine(album.id)
            hasher.combine(album.title)
            hasher.combine(album.clips)
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

    static func configureAlbumCell(thumbnailPipeline: Pipeline,
                                   queryService: ImageQueryServiceProtocol,
                                   delegate: AlbumListCollectionViewCellDelegate) -> UICollectionView.CellRegistration<AlbumListCollectionViewCell, Item>
    {
        return .init(cellNib: AlbumListCollectionViewCell.nib) { [weak thumbnailPipeline, weak queryService, weak delegate] cell, _, item in
            cell.albumId = item.album.id
            cell.title = item.album.title
            cell.clipCount = item.album.clips.count
            cell.delegate = delegate

            cell.setEditing(item.isEditing, animated: false)

            cell.setHiddenIconVisibility(true, animated: false)
            cell.setAlbumHiding(item.album.isHidden, animated: false)

            guard let pipeline = thumbnailPipeline,
                  let imageQueryService = queryService else { return }

            if let item = item.album.clips.first?.primaryItem {
                let scale = cell.traitCollection.displayScale
                let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
                let provider = ImageDataProvider(imageId: item.imageId,
                                                 cacheKey: "album-list-\(item.identity.uuidString)",
                                                 imageQueryService: imageQueryService)
                let request = ImageRequest(source: .provider(provider), size: size, scale: scale)
                cell.pipeline = pipeline
                loadImage(request, with: pipeline, on: cell, userInfo: [
                    "originalSize": item.imageSize.cgSize,
                    "cacheKey": request.source.cacheKey
                ])
            } else {
                cancelLoadImage(on: cell)
            }
        }
    }

    static func configureDataSource(collectionView: UICollectionView,
                                    thumbnailPipeline: Pipeline,
                                    queryService: ImageQueryServiceProtocol,
                                    delegate: AlbumListCollectionViewCellDelegate) -> DataSource
    {
        let albumCellRegistration = self.configureAlbumCell(thumbnailPipeline: thumbnailPipeline,
                                                            queryService: queryService,
                                                            delegate: delegate)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: item)
        }
    }
}
