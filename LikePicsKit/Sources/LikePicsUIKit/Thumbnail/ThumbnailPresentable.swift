//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public protocol ThumbnailPresentable {
    func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize
}
