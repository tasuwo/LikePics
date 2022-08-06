//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

public protocol ImageLoadSourceResolver {
    /// View Hierarchy にロードされた View
    ///
    /// - attention: WebViewをViewHierarchyに追加しデータをロードするために利用する
    var loadedView: PassthroughSubject<UIView, Never> { get }
    func resolveSources() -> Future<[ImageLoadSource], ImageLoadSourceResolverError>
}
