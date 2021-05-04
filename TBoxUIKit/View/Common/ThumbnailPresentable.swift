//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public protocol ThumbnailPresentable {
    func calcThumbnailImageSize(originalSize: CGSize?) -> CGSize
}
