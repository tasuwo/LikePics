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

    typealias Item = Clip
}

// MARK: - Layout

extension ClipCollectionViewLayout {
    static func createLayout(with delegate: ClipsCollectionLayoutDelegate) -> UICollectionViewLayout {
        let layout = ClipCollectionLayout()
        layout.delegate = delegate
        return layout
    }
}

// MARK: - DataSource

extension ClipCollectionViewLayout {
    static func configureDataSource(collectionView: UICollectionView,
                                    thumbnailLoader: ThumbnailLoaderProtocol) -> DataSource
    {
        let cellRegistration = configureCell(collectionView: collectionView, thumbnailLoader: thumbnailLoader)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    private static func configureCell(collectionView: UICollectionView,
                                      thumbnailLoader: ThumbnailLoaderProtocol) -> UICollectionView.CellRegistration<ClipCollectionViewCell, Item>
    {
        return .init(cellNib: ClipCollectionViewCell.nib) { [weak collectionView, weak thumbnailLoader] cell, _, clip in
            let requestId = UUID().uuidString
            cell.identifier = requestId

            cell.setHiddenIconVisibility(true, animated: false)
            cell.setClipHiding(clip.isHidden, animated: false)

            cell.visibleSelectedMark = collectionView?.isEditing ?? false

            guard let thumbnailLoader = thumbnailLoader else { return }

            let scale = cell.traitCollection.displayScale

            var requests: [ThumbnailRequest] = []

            if let item = clip.primaryItem {
                requests.append(self.makeRequest(for: item, id: requestId, size: cell.primaryImageView.bounds.size, scale: scale, context: .primary))
            } else {
                cell.primaryImage = .noImage
            }

            if let item = clip.secondaryItem {
                requests.append(self.makeRequest(for: item, id: requestId, size: cell.secondaryImageView.bounds.size, scale: scale, context: .secondary))
            } else {
                cell.secondaryImage = .noImage
            }

            if let item = clip.tertiaryItem {
                requests.append(self.makeRequest(for: item, id: requestId, size: cell.tertiaryImageView.bounds.size, scale: scale, context: .tertiary))
            } else {
                cell.tertiaryImage = .noImage
            }

            cell.onReuse = { [weak thumbnailLoader] identifier in
                guard identifier == requestId else { return }
                requests.forEach { thumbnailLoader?.cancel($0) }
            }

            requests.forEach { thumbnailLoader.load($0, observer: cell) }
        }
    }

    private static func makeRequest(for item: ClipItem,
                                    id: String,
                                    size: CGSize,
                                    scale: CGFloat,
                                    context: ClipCollectionViewCell.ThumbnailLoadingUserInfoValue,
                                    isPrefetch: Bool = false) -> ThumbnailRequest
    {
        // - SeeAlso: PreviewLoader
        let info = ThumbnailRequest.ThumbnailInfo(id: "clip-collection-\(item.identity.uuidString)",
                                                  size: size,
                                                  scale: scale)
        let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
        return ThumbnailRequest(requestId: id,
                                originalImageRequest: imageRequest,
                                thumbnailInfo: info,
                                isPrefetch: isPrefetch,
                                userInfo: [ClipCollectionViewCell.ThumbnailLoadingUserInfoKey: context.rawValue])
    }
}
