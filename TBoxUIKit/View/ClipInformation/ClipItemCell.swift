//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipItemCell: UICollectionViewListCell {
    public var identifier: String?
    public weak var invalidator: ThumbnailInvalidatable?

    public var onReuse: ((String?) -> Void)?

    private var _contentConfiguration: ClipItemContentConfiguration {
        return (contentConfiguration as? ClipItemContentConfiguration) ?? ClipItemContentConfiguration()
    }

    override public func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = _contentConfiguration.updated(for: state)
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
    }
}

extension ClipItemCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        let baseWidth = frame.width
        if let originalSize = originalPixelSize {
            if originalSize.width < originalSize.height {
                return .init(width: baseWidth,
                             height: baseWidth * (originalSize.height / originalSize.width))
            } else {
                return .init(width: baseWidth * (originalSize.width / originalSize.height),
                             height: baseWidth)
            }
        } else {
            return .init(width: baseWidth, height: baseWidth)
        }
    }
}

extension ClipItemCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        // NOP
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            var configuration = self._contentConfiguration
            configuration.image = nil
            self.contentConfiguration = configuration
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            var configuration = self._contentConfiguration
            configuration.image = image
            self.contentConfiguration = configuration

            guard let image = configuration.image else { return }
            let displayScale = self.traitCollection.displayScale
            let originalSize = request.userInfo?[.originalImageSize] as? CGSize
            if self.shouldInvalidate(thumbnail: image, originalImageSize: originalSize, displayScale: displayScale) {
                self.invalidator?.invalidateCache(having: request.config.cacheKey)
            }
        }
    }
}
