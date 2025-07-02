//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public enum ClipPreviewSource: Equatable {
    case image(UIImage)
    case thumbnail(UIImage?, originalSize: CGSize)

    var uiImage: UIImage? {
        switch self {
        case let .image(image):
            return image

        case let .thumbnail(image, _):
            return image
        }
    }

    var size: CGSize {
        switch self {
        case let .image(image):
            return image.size

        case let .thumbnail(_, size):
            return size
        }
    }

    var originalSize: CGSize? {
        switch self {
        case .image:
            return nil

        case let .thumbnail(_, originalSize: size):
            return size
        }
    }

    var originalSizeInPixel: CGSize {
        switch self {
        case let .image(image):
            return .init(
                width: image.size.width * image.scale,
                height: image.size.height * image.scale
            )

        case let .thumbnail(_, size):
            return size
        }
    }
}
