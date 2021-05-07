//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

public enum ClipInformationTransitionMode {
    case custom(interactive: Bool)
    case `default`

    static let initialValue: Self = .custom(interactive: false)
}

public protocol ClipInformationTransitioningControllerProtocol: UIViewControllerTransitioningDelegate {
    var isInteractive: Bool { get }
    func isLocked(by id: UUID) -> Bool
    @discardableResult
    func beginTransition(id: UUID, mode: ClipInformationTransitionMode) -> Bool
    @discardableResult
    func didPanForPresentation(id: UUID, sender: UIPanGestureRecognizer) -> Bool
    @discardableResult
    func didPanForDismissal(id: UUID, sender: UIPanGestureRecognizer) -> Bool
}

public class ClipInformationTransitioningController: NSObject {
    private var presentationInteractiveAnimator: ClipInformationInteractivePresentationAnimator?
    private var dismissalInteractiveAnimator: ClipInformationInteractiveDismissalAnimator?
    private var transitionMode: ClipInformationTransitionMode = .initialValue
    private let lock: TransitionLock
    private let logger: Loggable

    // MARK: - Lifecycle

    public init(lock: TransitionLock, logger: Loggable) {
        self.lock = lock
        self.logger = logger
    }
}

extension ClipInformationTransitioningController: ClipInformationTransitioningControllerProtocol {
    // MARK: - ClipInformationTransitioningControllerProtocol

    public var isInteractive: Bool {
        guard case .custom(interactive: true) = self.transitionMode else { return false }
        return true
    }

    public func isLocked(by id: UUID) -> Bool {
        lock.isLocked(by: id)
    }

    @discardableResult
    public func beginTransition(id: UUID, mode: ClipInformationTransitionMode) -> Bool {
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

extension ClipInformationTransitioningController: ClipInformationAnimatorDelegate {
    // MARK: - ClipInformationAnimatorDelegate

    func clipInformationAnimatorDelegate(_ animator: ClipInformationAnimator, didComplete: Bool) {
        lock.releaseLock()
        self.transitionMode = .initialValue
    }
}

extension ClipInformationTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        switch self.transitionMode {
        case .custom:
            let fallback = FadeTransitionAnimator(logger: self.logger)
            return ClipInformationPresentationAnimator(delegate: self, fallbackAnimator: fallback)

        default:
            return nil
        }
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch self.transitionMode {
        case .custom:
            let fallback = FadeTransitionAnimator(logger: self.logger)
            return ClipInformationDismissalAnimator(delegate: self, fallbackAnimator: fallback)

        default:
            return nil
        }
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            let fallback = FadeTransitionAnimator(logger: self.logger)
            self.presentationInteractiveAnimator = ClipInformationInteractivePresentationAnimator(logger: self.logger,
                                                                                                  fallbackAnimator: fallback)
            return self.presentationInteractiveAnimator

        default:
            return nil
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            let fallback = FadeTransitionAnimator(logger: self.logger)
            self.dismissalInteractiveAnimator = ClipInformationInteractiveDismissalAnimator(logger: self.logger,
                                                                                            fallbackAnimator: fallback)
            return self.dismissalInteractiveAnimator

        default:
            return nil
        }
    }
}
