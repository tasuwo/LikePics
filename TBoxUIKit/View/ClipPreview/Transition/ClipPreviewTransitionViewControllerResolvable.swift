//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public typealias ClipPreviewPresentingViewController = ClipPreviewPresentingAnimatorDataSource & UIViewController
public typealias ClipPreviewPresentedViewController = ClipPreviewPresentedAnimatorDataSource & UIViewController

public protocol ClipPreviewTransitionViewControllerResolvable: AnyObject {
    func resolvePresentingViewController(from baseViewController: UIViewController) -> ClipPreviewPresentingAnimatorDataSource?

    func resolvePresentedViewController(from baseViewController: UIViewController) -> ClipPreviewPresentedAnimatorDataSource?
}
