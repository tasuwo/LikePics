//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import UIKit
import WebKit

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard viewControllers.count > 1 else {
            return false
        }

        guard let currentViewController = topViewController else {
            return false
        }

        if currentViewController.isEditing {
            return false
        }

        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // エッジスワイプと他のジェスチャを共存させない
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // WebView を利用していた場合、そちらを優先させる
        if let webView = otherGestureRecognizer.view as? WKWebView {
            guard webView.allowsBackForwardNavigationGestures else { return false }
            return !webView.canGoBack
        }

        // 他の PanGesture よりもエッジスワイプを優先させる
        return otherGestureRecognizer is UIPanGestureRecognizer
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}
