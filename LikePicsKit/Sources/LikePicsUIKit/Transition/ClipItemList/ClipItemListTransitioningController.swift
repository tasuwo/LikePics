//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

public class ClipItemListTransitioningController: NSObject {
    private let lock: TransitionLock
    private let logger: Loggable

    // MARK: - Initializers

    public init(lock: TransitionLock, logger: Loggable) {
        self.lock = lock
        self.logger = logger
    }
}

extension ClipItemListTransitioningController: ClipItemListTransitioningControllable {
    // MARK: - ClipItemListTransitioningControllable

    public func isLocked(by id: UUID) -> Bool {
        lock.isLocked(by: id)
    }

    public func beginTransition(id: UUID, mode: ClipPreviewTransitionType) -> Bool {
        guard lock.takeLock(id) else { return false }
        return true
    }
}

extension ClipItemListTransitioningController: AnimatorDelegate {
    // MARK: - AnimatorDelegate

    func animator(_ animator: Animator, didComplete: Bool) {
        lock.releaseLock()
    }
}

extension ClipItemListTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        let fallback = FadeTransitionAnimator(logger: self.logger)
        return ClipItemListPresentationAnimator(delegate: self, fallbackAnimator: fallback)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let fallback = FadeTransitionAnimator(logger: self.logger)
        return ClipItemListDismissalAnimator(delegate: self, fallbackAnimator: fallback)
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
}
