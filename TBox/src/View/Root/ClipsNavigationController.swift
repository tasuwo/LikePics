//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipsNavigationController: UINavigationController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }
}

extension ClipsNavigationController: UINavigationControllerDelegate {
    // MARK: - UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        switch operation {
        case .push:
            return ClipPreviewPresentTransitionAnimator()
        case .pop:
            return ClipPreviewDismissTransitionAnimator()
        default:
            return nil
        }
    }
}
