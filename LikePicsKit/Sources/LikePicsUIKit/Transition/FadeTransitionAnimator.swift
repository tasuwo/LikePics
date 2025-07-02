//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit
import os.log

protocol FadeTransitionAnimatorProtocol {
    func startTransition(_ transitionContext: UIViewControllerContextTransitioning, withDuration duration: TimeInterval, isInteractive: Bool)
}

class FadeTransitionAnimator {
    private let logger = Logger(LogHandler.transition)
}

extension FadeTransitionAnimator: FadeTransitionAnimatorProtocol {
    // MARK: - FadeTransitionAnimatorProtocol

    func startTransition(_ transitionContext: UIViewControllerContextTransitioning, withDuration duration: TimeInterval, isInteractive: Bool) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from),
            let to = transitionContext.viewController(forKey: .to)
        else {
            if isInteractive {
                transitionContext.cancelInteractiveTransition()
            }
            transitionContext.completeTransition(false)
            self.logger.error("Filed to fade transition:")
            if transitionContext.viewController(forKey: .from) == nil {
                self.logger.error("- From ViewController not found.")
            }
            if transitionContext.viewController(forKey: .to) == nil {
                self.logger.error("- To ViewController not found.")
            }
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.insertSubview(to.view, belowSubview: from.view)

        UIView.likepics_animate(
            withDuration: duration,
            animations: {
                from.view.alpha = 0
            },
            completion: { _ in
                from.view.alpha = 1
                if isInteractive {
                    transitionContext.finishInteractiveTransition()
                }
                transitionContext.completeTransition(true)
            }
        )
    }
}
