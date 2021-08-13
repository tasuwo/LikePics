//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public typealias ClipPreviewPresentingViewController = ClipPreviewPresentable & UIViewController
public typealias ClipPreviewPresentedViewController = ClipPreviewPresenting & UIViewController

public protocol ClipPreviewTransitionViewControllerResolvable: AnyObject {
    func resolvePresentingViewController(from baseViewController: UIViewController) -> ClipPreviewPresentable?

    func resolvePresentedViewController(from baseViewController: UIViewController) -> ClipPreviewPresenting?
}
