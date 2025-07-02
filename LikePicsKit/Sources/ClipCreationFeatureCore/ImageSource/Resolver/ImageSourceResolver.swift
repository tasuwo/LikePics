//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public protocol ImageSourceResolver {
    /// View Hierarchy にロードされた View
    ///
    /// - attention: WebViewをViewHierarchyに追加しデータをロードするために利用する
    #if canImport(UIKit)
    var loadedView: PassthroughSubject<UIView, Never> { get }
    #endif
    #if canImport(AppKit)
    var loadedView: PassthroughSubject<NSView, Never> { get }
    #endif
    func resolveSources() -> Future<[ImageSource], ImageSourceResolverError>
}
