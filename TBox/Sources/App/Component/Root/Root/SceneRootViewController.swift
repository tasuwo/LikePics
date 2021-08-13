//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol SceneRootViewController: UIViewController, CloudStackLoaderObserver, ClipPreviewPresentable {
    var currentViewController: UIViewController? { get }
    func select(_ barItem: SceneRoot.BarItem)
}
