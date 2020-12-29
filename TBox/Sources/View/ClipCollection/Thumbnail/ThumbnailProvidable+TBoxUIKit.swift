//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

enum ClipCollectionViewCellThumbnailContext {
    case primary
    case secondary
    case tertiary
}

extension ClipCollectionViewCell: ThumbnailProvidable {
    // MARK: - ThumbnailProvidable

    func set(thumbnail: Thumbnail?, context: Any?) {
        guard let ctx = context as? ClipCollectionViewCellThumbnailContext else { return }
        switch ctx {
        case .primary:
            self.primaryImage = thumbnail?.image

        case .secondary:
            self.secondaryImage = thumbnail?.image

        case .tertiary:
            self.tertiaryImage = thumbnail?.image
        }
    }

    func imageSize(context: Any?) -> CGSize {
        guard let ctx = context as? ClipCollectionViewCellThumbnailContext else {
            return CGSize(width: 300, height: 300)
        }
        switch ctx {
        case .primary:
            return self.primaryImageView.bounds.size

        case .secondary:
            return self.secondaryImageView.bounds.size

        case .tertiary:
            return self.tertiaryImageView.bounds.size
        }
    }
}

private extension Thumbnail {
    var image: ClipCollectionViewCell.Image {
        switch self {
        case let .loaded(image):
            return .loaded(image)

        case .failedToLoad:
            return .failedToLoad

        case .loading:
            return .loading

        case .noImage:
            return .noImage
        }
    }
}
