//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
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
                configuration.backgroundColor = Asset.Color.backgroundClient.color
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
    static func createDataSource(collectionView: UICollectionView,
                                 thumbnailLoader: ThumbnailLoaderProtocol) -> DataSource
    {
        let cellRegistration = self.configureCell(thumbnailLoader: thumbnailLoader)

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        return dataSource
    }

    private static func configureCell(thumbnailLoader: ThumbnailLoaderProtocol) -> UICollectionView.CellRegistration<AlbumSelectionCell, Album> {
        return .init(cellNib: AlbumSelectionCell.nib) { [weak thumbnailLoader] cell, _, album in
            cell.title = album.title
            cell.clipCount = album.clips.count

            if let thumbnailTarget = album.clips.first?.items.first {
                let requestId = UUID().uuidString
                cell.identifier = requestId
                let size = cell.calcThumbnailPointSize(originalPixelSize: thumbnailTarget.imageSize.cgSize)
                let info = ThumbnailConfig(cacheKey: "album-selection-list-\(thumbnailTarget.identity.uuidString)",
                                           size: size,
                                           scale: cell.traitCollection.displayScale)
                let imageRequest = ImageDataLoadRequest(imageId: thumbnailTarget.imageId)
                let request = ThumbnailRequest(requestId: requestId,
                                               originalImageRequest: imageRequest,
                                               config: info)
                thumbnailLoader?.load(request, observer: cell)
                cell.onReuse = { identifier in
                    guard identifier == requestId else { return }
                    thumbnailLoader?.cancel(request)
                }
            } else {
                cell.identifier = nil
                cell.thumbnail = nil
                cell.onReuse = nil
            }
        }
    }
}
