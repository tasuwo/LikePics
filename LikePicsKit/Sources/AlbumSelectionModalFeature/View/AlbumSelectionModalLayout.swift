//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
import UIKit

enum AlbumSelectionModalLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case main
    }

    typealias Item = Album
}

// MARK: - Layout

extension AlbumSelectionModalLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .main:
                var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
                configuration.backgroundColor = Asset.Color.background.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

            case .none:
                return nil
            }
        }
        return layout
    }
}

// MARK: - DataSource

extension AlbumSelectionModalLayout {
    static func createDataSource(_ collectionView: UICollectionView,
                                 _ thumbnailPipeline: Pipeline,
                                 _ imageQueryService: ImageQueryServiceProtocol) -> DataSource
    {
        let cellRegistration = self.configureCell(thumbnailPipeline: thumbnailPipeline,
                                                  imageQueryService: imageQueryService)

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        return dataSource
    }

    private static func configureCell(thumbnailPipeline: Pipeline,
                                      imageQueryService: ImageQueryServiceProtocol) -> UICollectionView.CellRegistration<AlbumSelectionCell, Album>
    {
        return .init(cellNib: AlbumSelectionCell.nib) { [weak thumbnailPipeline, weak imageQueryService] cell, _, album in
            cell.title = album.title
            cell.clipCount = album.clips.count

            guard let pipeline = thumbnailPipeline,
                  let imageQueryService = imageQueryService,
                  let thumbnailTarget = album.clips.first?.items.first
            else {
                cell.thumbnailImageView.smt.cancelLoadImage()
                return
            }

            let scale = cell.traitCollection.displayScale
            let size = cell.calcThumbnailPointSize(originalPixelSize: thumbnailTarget.imageSize.cgSize)
            let provider = ImageDataProvider(imageId: thumbnailTarget.imageId,
                                             cacheKey: "album-selection-list-\(thumbnailTarget.identity.uuidString)",
                                             imageQueryService: imageQueryService)
            let request = ImageRequest(source: .provider(provider),
                                       resize: .init(size: size, scale: scale))
            cell.thumbnailImageView.smt.loadImage(request, with: pipeline)
        }
    }
}