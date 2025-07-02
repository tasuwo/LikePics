//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public enum ImageSource {
    case memoryCache
    case diskCache
    case processed
}

public struct ImageResponse {
    #if canImport(UIKit)
    public let image: UIImage
    #endif
    #if canImport(AppKit)
    public let image: NSImage
    #endif
    public let diskCacheImageSize: CGSize?
    public let source: ImageSource
}
