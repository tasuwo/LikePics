//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipItemEditListCell: UICollectionViewListCell {
    public var identifier: String?

    public var onReuse: ((String?) -> Void)?

    private var _contentConfiguration: ClipItemEditContentConfiguration {
        return (contentConfiguration as? ClipItemEditContentConfiguration) ?? ClipItemEditContentConfiguration()
    }

    override public func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = _contentConfiguration.updated(for: state)
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
    }
}

extension ClipItemEditListCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        if let originalSize = originalPixelSize {
            // See: ClipItemEditContentView
            return .init(width: 100,
                         height: 100 * originalSize.height / originalSize.width)
        } else {
            return .init(width: 100, height: 100)
        }
    }
}

extension ClipItemEditListCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        // NOP
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            var configuration = self._contentConfiguration
            configuration.thumbnail = nil
            self.contentConfiguration = configuration
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            var configuration = self._contentConfiguration
            configuration.thumbnail = image
            self.contentConfiguration = configuration
        }
    }
}
