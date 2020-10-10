//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

protocol FadeTransitionAnimatorProtocol {
    func startTransition(_ transitionContext: UIViewControllerContextTransitioning, withDuration duration: TimeInterval, isInteractive: Bool)
}

class FadeTransitionAnimator {
    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(logger: TBoxLoggable) {
        self.logger = logger
    }
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
            self.logger.write(ConsoleLog(level: .error, message: "Filed to fade transition:"))
            if transitionContext.viewController(forKey: .from) == nil {
                self.logger.write(ConsoleLog(level: .error, message: "- From ViewController not found."))
            }
            if transitionContext.viewController(forKey: .to) == nil {
                self.logger.write(ConsoleLog(level: .error, message: "- To ViewController not found."))
            }
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.insertSubview(to.view, belowSubview: from.view)

        UIView.animate(
            withDuration: duration,
            animations: {
                from.view.alpha = 0
            },
            completion: { _ in
                if isInteractive {
                    transitionContext.finishInteractiveTransition()
                }
                transitionContext.completeTransition(true)
            }
        )
    }
}
