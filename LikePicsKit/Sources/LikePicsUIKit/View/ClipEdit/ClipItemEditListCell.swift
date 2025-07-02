//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipItemEditListCell: UICollectionViewListCell {
    private var _contentConfiguration: ClipItemEditContentConfiguration {
        return (contentConfiguration as? ClipItemEditContentConfiguration) ?? ClipItemEditContentConfiguration()
    }

    override public func updateConfiguration(using state: UICellConfigurationState) {
        contentConfiguration = _contentConfiguration.updated(for: state)
    }
}

extension ClipItemEditListCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        if let originalSize = originalPixelSize {
            // See: ClipItemEditContentView
            return .init(
                width: 100,
                height: 100 * originalSize.height / originalSize.width
            )
        } else {
            return .init(width: 100, height: 100)
        }
    }
}

// MARK: - ImageDisplayable

extension ClipItemEditListCell: ImageDisplayable {
    public func smt_display(_ image: UIImage?) {
        var configuration = self._contentConfiguration

        defer {
            self.contentConfiguration = configuration
        }

        guard let image = image else {
            configuration.thumbnail = nil
            return
        }

        configuration.thumbnail = image
    }
}
