//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

public enum ClipPreviewTransitionMode {
    case custom(interactive: Bool)
    case `default`

    static let initialValue: Self = .custom(interactive: false)
}

public protocol ClipPreviewTransitionControllerProtocol {
    var isInteractive: Bool { get }
    func isLocked(by id: UUID) -> Bool
    @discardableResult
    func beginTransition(id: UUID, mode: ClipPreviewTransitionMode) -> Bool
    @discardableResult
    func didPanForDismissal(id: UUID, sender: UIPanGestureRecognizer) -> Bool
}

public class ClipPreviewTransitioningController: NSObject {
    private let lock: TransitionLock
    private let logger: TBoxLoggable
    private var dismissalInteractiveAnimator: ClipPreviewInteractiveDismissalAnimator?
    private var transitionMode: ClipPreviewTransitionMode = .initialValue

    // MARK: - Lifecycle

    public init(lock: TransitionLock, logger: TBoxLoggable) {
        self.lock = lock
        self.logger = logger
    }
}

extension ClipPreviewTransitioningController: ClipPreviewTransitionControllerProtocol {
    // MARK: - ClipPreviewTransitionControllerProtocol

    public var isInteractive: Bool {
        guard case .custom(interactive: true) = self.transitionMode else { return false }
        return true
    }

    public func isLocked(by id: UUID) -> Bool {
        lock.isLocked(by: id)
    }

    public func beginTransition(id: UUID, mode: ClipPreviewTransitionMode) -> Bool {
        guard lock.takeLock(id) else { return false }
        self.transitionMode = mode
        return true
    }

    public func didPanForDismissal(id: UUID, sender: UIPanGestureRecognizer) -> Bool {
        guard lock.isLocked(by: id) else { return false }
        self.dismissalInteractiveAnimator?.didPan(sender: sender)
        return true
    }
}

extension ClipPreviewTransitioningController: ClipPreviewAnimatorDelegate {
    // MARK: - ClipPreviewAnimatorDelegate

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, didComplete: Bool) {
        lock.releaseLock()
        self.transitionMode = .initialValue
    }
}

extension ClipPreviewTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        switch self.transitionMode {
        case .custom:
            let fallback = FadeTransitionAnimator(logger: self.logger)
            return ClipPreviewPresentationAnimator(delegate: self, fallbackAnimator: fallback)

        default:
            return nil
        }
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch self.transitionMode {
        case .custom:
            let fallback = FadeTransitionAnimator(logger: self.logger)
            return ClipPreviewDismissalAnimator(delegate: self, fallbackAnimator: fallback)

        default:
            return nil
        }
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if case .custom(interactive: true) = self.transitionMode {
            self.logger.write(ConsoleLog(level: .error, message: "Cannot use interactive transition for presenting ClipPreview."))
        }
        return nil
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            let fallback = FadeTransitionAnimator(logger: self.logger)
            self.dismissalInteractiveAnimator = ClipPreviewInteractiveDismissalAnimator(logger: self.logger,
                                                                                        fallbackAnimator: fallback)
            return self.dismissalInteractiveAnimator

        default:
            return nil
        }
    }
}

extension ClipPreviewTransitioningController: UINavigationControllerDelegate {
    // MARK: - UINavigationControllerDelegate

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        switch (operation, self.transitionMode) {
        case (.push, .custom):
            let fallback = FadeTransitionAnimator(logger: self.logger)
            return ClipPreviewPresentationAnimator(delegate: self, fallbackAnimator: fallback)

        case (.push, _):
            return nil

        case (.pop, .custom):
            let fallback = FadeTransitionAnimator(logger: self.logger)
            return ClipPreviewDismissalAnimator(delegate: self, fallbackAnimator: fallback)

        case (.pop, _):
            return nil

        default:
            return nil
        }
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
    {
        switch self.transitionMode {
        case .custom(interactive: true):
            guard animationController is ClipPreviewDismissalAnimator else {
                self.logger.write(ConsoleLog(level: .error, message: "Interactive transition for presenting ClipPreview is unsupported."))
                return nil
            }
            let fallback = FadeTransitionAnimator(logger: self.logger)
            self.dismissalInteractiveAnimator = ClipPreviewInteractiveDismissalAnimator(logger: self.logger,
                                                                                        fallbackAnimator: fallback)
            return self.dismissalInteractiveAnimator

        default:
            return nil
        }
    }
}
