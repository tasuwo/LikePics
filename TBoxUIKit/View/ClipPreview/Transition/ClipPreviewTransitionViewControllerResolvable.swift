//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public typealias ClipPreviewPresentingViewController = ClipPreviewPresentableViewController & UIViewController
public typealias ClipPreviewPresentedViewController = ClipPreviewViewController & UIViewController

public protocol ClipPreviewTransitionViewControllerResolvable: AnyObject {
    func resolvePresentingViewController(from baseViewController: UIViewController) -> ClipPreviewPresentableViewController?

    func resolvePresentedViewController(from baseViewController: UIViewController) -> ClipPreviewViewController?
}
