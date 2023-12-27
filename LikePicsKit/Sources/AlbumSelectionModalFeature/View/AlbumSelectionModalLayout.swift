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
    @MainActor
    static func createDataSource(_ collectionView: UICollectionView,
                                 _ thumbnailProcessingQueue: ImageProcessingQueue,
                                 _ imageQueryService: ImageQueryServiceProtocol) -> DataSource
    {
        let cellRegistration = self.configureCell(thumbnailProcessingQueue: thumbnailProcessingQueue,
                                                  imageQueryService: imageQueryService)

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        return dataSource
    }

    @MainActor
    private static func configureCell(thumbnailProcessingQueue: ImageProcessingQueue,
                                      imageQueryService: ImageQueryServiceProtocol) -> UICollectionView.CellRegistration<AlbumSelectionCell, Album>
    {
        return .init(cellNib: AlbumSelectionCell.nib) { [weak thumbnailProcessingQueue, weak imageQueryService] cell, _, album in
            cell.title = album.title
            cell.clipCount = album.clips.count

            guard let processingQueue = thumbnailProcessingQueue,
                  let imageQueryService = imageQueryService,
                  let thumbnailTarget = album.clips.first?.items.first
            else {
                cell.thumbnailImageView.smt.cancelLoadImage()
                return
            }

            let scale = cell.traitCollection.displayScale
            let size = cell.calcThumbnailPointSize(originalPixelSize: thumbnailTarget.imageSize.cgSize)
            let request = ImageRequest(resize: .init(size: size, scale: scale), cacheKey: "album-selection-list-\(thumbnailTarget.identity.uuidString)") { [imageQueryService, thumbnailTarget] in
                return try? imageQueryService.read(having: thumbnailTarget.imageId)
            }
            cell.thumbnailImageView.smt.loadImage(request, with: processingQueue)
        }
    }
}
