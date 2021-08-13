//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

public protocol ClipItemListTransitionControllable: UIViewControllerTransitioningDelegate {
    func isLocked(by id: UUID) -> Bool
    @discardableResult
    func beginTransition(id: UUID, mode: ClipPreviewTransitionMode) -> Bool
}

public class ClipItemListTransitioningController: NSObject {
    private let lock: TransitionLock
    private let logger: Loggable

    // MARK: - Initializers

    public init(lock: TransitionLock, logger: Loggable) {
        self.lock = lock
        self.logger = logger
    }
}

extension ClipItemListTransitioningController: ClipItemListTransitionControllable {
    // MARK: - ClipItemListTransitionControllable

    public func isLocked(by id: UUID) -> Bool {
        lock.isLocked(by: id)
    }

    public func beginTransition(id: UUID, mode: ClipPreviewTransitionMode) -> Bool {
        guard lock.takeLock(id) else { return false }
        return true
    }
}

extension ClipItemListTransitioningController: ClipItemListAnimatorDelegate {
    // MARK: - ClipItemListAnimatorDelegate

    func clipItemListAnimatorDelegate(_ animator: ClipItemListAnimator, didComplete: Bool) {
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
