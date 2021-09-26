//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipItemCell: UICollectionViewListCell {
    public weak var pipeline: Pipeline?

    private var _contentConfiguration: ClipItemContentConfiguration {
        return (contentConfiguration as? ClipItemContentConfiguration) ?? ClipItemContentConfiguration()
    }

    override public func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = _contentConfiguration.updated(for: state)
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

// MARK: - ImageDisplayable

extension ClipItemCell: ImageDisplayable {
    public func smt_willLoad(userInfo: [AnyHashable: Any]?) {
        var configuration = self._contentConfiguration
        configuration.image = nil
        self.contentConfiguration = configuration
    }

    public func smt_display(_ image: UIImage?, userInfo: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            var configuration = self._contentConfiguration

            defer {
                self.contentConfiguration = configuration
            }

            configuration.image = image

            guard let image = image,
                  let originalSize = userInfo?["originalSize"] as? CGSize,
                  let cacheKey = userInfo?["cacheKey"] as? String
            else {
                return
            }

            let displayScale = self.traitCollection.displayScale
            if self.shouldInvalidate(thumbnail: image, originalImageSize: originalSize, displayScale: displayScale) {
                self.pipeline?.config.diskCache?.remove(forKey: cacheKey)
                self.pipeline?.config.memoryCache.remove(forKey: cacheKey)
            }
        }
    }
}

extension ClipItemCell: ClipPreviewPresentableCell {
    public func thumbnail() -> UIImageView {
        // swiftlint:disable:next force_unwrapping
        (contentView as? ClipItemContentView)!.thumbnailImageView
    }
}

extension ClipItemCell: ClipItemListPresentingCell {
    public func calcImageFrame(size: CGSize) -> CGRect {
        // swiftlint:disable:next force_unwrapping
        (contentView as? ClipItemContentView)!.calcImageFrame(size: size)
    }
}
