//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import UIKit

protocol ThumbnailRenderable: AnyObject {
    var thumbnailLoadingQueue: DispatchQueue { get }
    var thumbnailLoader: ThumbnailLoaderProtocol { get }
    var cancellableBag: Set<AnyCancellable> { get set }
}

extension ThumbnailRenderable {
    func load(_ item: ClipItem?, to view: ThumbnailProvidable, context: Any?, traitCollection: UITraitCollection) {
        guard let item = item else {
            view.set(thumbnail: .noImage, context: context)
            return
        }

        let size = view.imageSize(context: context)
        let scale = traitCollection.displayScale

        if let cachedImage = self.thumbnailLoader.readCache(for: item) {
            view.set(thumbnail: .loaded(cachedImage), context: context)
        } else {
            view.set(thumbnail: .loading, context: context)
            self.thumbnailLoadingQueue.async {
                self.thumbnailLoader.load(for: item, pointSize: size, scale: scale)
                    .filter { _ in view.identifier == item.clipId }
                    .map { Thumbnail(loaded: $0) }
                    .receive(on: DispatchQueue.main)
                    .sink { view.set(thumbnail: $0, context: context) }
                    .store(in: &self.cancellableBag)
            }
        }
    }

    func prefetch(_ item: ClipItem?, pointSize: CGSize, traitCollection: UITraitCollection) {
        guard let item = item else { return }

        let size = pointSize
        let scale = traitCollection.displayScale

        self.thumbnailLoadingQueue.async {
            self.thumbnailLoader.load(for: item, pointSize: size, scale: scale)
                .sink { _ in }
                .store(in: &self.cancellableBag)
        }
    }
}
