//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

class ClipCollectionPreLoader: NSObject {
    typealias Layout = ClipCollectionViewLayout

    let dataSource: Layout.DataSource
    let thumbnailLoader: ThumbnailLoaderProtocol

    private let queue = DispatchQueue(label: "net.tasuwo.TBox.ClipCollectionPreLoader")
    private var requestsByIndexPath: [IndexPath: [ThumbnailRequest]] = [:]

    // MARK: - Initializers

    init(dataSource: Layout.DataSource, thumbnailLoader: ThumbnailLoaderProtocol) {
        self.dataSource = dataSource
        self.thumbnailLoader = thumbnailLoader
    }

    // MARK: - Methods

    private static func makeRequest(for item: ClipItem,
                                    id: String,
                                    size: CGSize,
                                    scale: CGFloat,
                                    context: IndexPath) -> ThumbnailRequest
    {
        // - SeeAlso: PreviewLoader
        let info = ThumbnailConfig(cacheKey: "clip-collection-\(item.identity.uuidString)",
                                   size: size,
                                   scale: scale)
        let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
        return ThumbnailRequest(requestId: id,
                                originalImageRequest: imageRequest,
                                config: info,
                                userInfo: [.prefetchingIndexPath: context])
    }
}

extension ClipCollectionPreLoader: UICollectionViewDataSourcePrefetching {
    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)

        guard let layout = collectionView.collectionViewLayout as? ClipCollectionWaterfallLayout else { return }

        for indexPath in indexPaths {
            guard let clip = dataSource.itemIdentifier(for: indexPath) else { return }

            let requestId = UUID().uuidString

            var requests: [ThumbnailRequest] = []

            let scale = collectionView.traitCollection.displayScale

            if let item = clip.primaryItem {
                let size = layout.calcExpectedThumbnailWidth(originalSize: item.imageSize.cgSize)
                requests.append(Self.makeRequest(for: item, id: requestId, size: size, scale: scale, context: indexPath))
            }

            if let item = clip.secondaryItem {
                let size = layout.calcExpectedThumbnailWidth(originalSize: item.imageSize.cgSize)
                requests.append(Self.makeRequest(for: item, id: requestId, size: size, scale: scale, context: indexPath))
            }

            if let item = clip.tertiaryItem {
                let size = layout.calcExpectedThumbnailWidth(originalSize: item.imageSize.cgSize)
                requests.append(Self.makeRequest(for: item, id: requestId, size: size, scale: scale, context: indexPath))
            }

            requests.forEach { thumbnailLoader.prefetch($0, observer: self) }
            self.requestsByIndexPath[indexPath] = requests
        }
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        assert(Thread.isMainThread)

        for indexPath in indexPaths {
            guard let requests = requestsByIndexPath[indexPath] else { continue }
            requestsByIndexPath.removeValue(forKey: indexPath)
            requests.forEach { thumbnailLoader.cancel($0) }
        }
    }
}

extension ClipCollectionPreLoader: ThumbnailPrefetchObserver {
    // MARK: - ThumbnailPrefetchObserver

    func didComplete(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard let indexPath = request.userInfo?[.prefetchingIndexPath] as? IndexPath else { return }
            self.requestsByIndexPath.removeValue(forKey: indexPath)
        }
    }
}
