//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipItemInformationTransitioningController: NSObject {
    private var presentationInteractiveAnimator: ClipItemInformationInteractivePresentationAnimator?
    private var dismissalInteractiveAnimator: ClipItemInformationInteractiveDismissalAnimator?
    private var transitionMode: ClipItemInformationTransitionType = .initialValue
    private let lock: TransitionLock

    // MARK: - Lifecycle

    public init(lock: TransitionLock) {
        self.lock = lock
    }
}

extension ClipItemInformationTransitioningController: ClipItemInformationTransitioningControllable {
    // MARK: - ClipItemInformationTransitioningControllable

    public var isInteractive: Bool {
        guard case .custom(interactive: true) = self.transitionMode else { return false }
        return true
    }

    public func isLocked(by id: UUID) -> Bool {
        lock.isLocked(by: id)
    }

    @discardableResult
    public func beginTransition(id: UUID, mode: ClipItemInformationTransitionType) -> Bool {
        guard lock.takeLock(id) else { return false }
        transitionMode = mode
        return true
    }

    @discardableResult
    public func didPanForDismissal(id: UUID, sender: UIPanGestureRecognizer) -> Bool {
        guard lock.isLocked(by: id) else { return false }
        self.dismissalInteractiveAnimator?.didPan(sender: sender)
        return true
    }

    @discardableResult
    public func didPanForPresentation(id: UUID, sender: UIPanGestureRecognizer) -> Bool {
        guard lock.isLocked(by: id) else { return false }
        self.presentationInteractiveAnimator?.didPan(sender: sender)
        return true
    }
}

extension ClipItemInformationTransitioningController: AnimatorDelegate {
    // MARK: - AnimatorDelegate

    func animator(_ animator: Animator, didComplete: Bool) {
        lock.releaseLock()
        self.transitionMode = .initialValue
    }
}

extension ClipItemInformationTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        switch self.transitionMode {
        case .custom:
            let fallback = FadeTransitionAnimator()
            return ClipItemInformationPresentationAnimator(delegate: self, fallbackAnimator: fallback)

        default:
            return nil
        }
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch self.transitionMode {
        case .custom:
            let fallback = FadeTransitionAnimator()
            return ClipItemInformationDismissalAnimator(delegate: self, fallbackAnimator: fallback)

        default:
            return nil
        }
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            let fallback = FadeTransitionAnimator()
            self.presentationInteractiveAnimator = ClipItemInformationInteractivePresentationAnimator(fallbackAnimator: fallback)
            return self.presentationInteractiveAnimator

        default:
            return nil
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            let fallback = FadeTransitionAnimator()
            self.dismissalInteractiveAnimator = ClipItemInformationInteractiveDismissalAnimator(fallbackAnimator: fallback)
            return self.dismissalInteractiveAnimator

        default:
            return nil
        }
    }
}
