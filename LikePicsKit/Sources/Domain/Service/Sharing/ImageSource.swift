//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public enum ImageSouce {
    case fileUrl(URL)
    case webUrl(URL)
    case data(Data)
    #if canImport(UIKit)
    case uiImage(UIImage)
    #endif
    #if canImport(AppKit)
    case nsImage(NSImage)
    #endif
}
