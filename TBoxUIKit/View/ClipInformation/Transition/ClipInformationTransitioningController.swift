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
    func beginTransition(_ mode: ClipInformationTransitionMode)
    func didPanForPresentation(sender: UIPanGestureRecognizer)
    func didPanForDismissal(sender: UIPanGestureRecognizer)
}

public class ClipInformationTransitioningController: NSObject {
    private var presentationInteractiveAnimator: ClipInformationInteractivePresentationAnimator?
    private var dismissalInteractiveAnimator: ClipInformationInteractiveDismissalAnimator?
    private var transitionMode: ClipInformationTransitionMode = .initialValue
    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    public init(logger: TBoxLoggable) {
        self.logger = logger
    }
}

extension ClipInformationTransitioningController: ClipInformationTransitioningControllerProtocol {
    // MARK: - ClipInformationTransitioningControllerProtocol

    public var isInteractive: Bool {
        guard case .custom(interactive: true) = self.transitionMode else { return false }
        return true
    }

    public func beginTransition(_ mode: ClipInformationTransitionMode) {
        self.transitionMode = mode
    }

    public func didPanForDismissal(sender: UIPanGestureRecognizer) {
        self.dismissalInteractiveAnimator?.didPan(sender: sender)
    }

    public func didPanForPresentation(sender: UIPanGestureRecognizer) {
        self.presentationInteractiveAnimator?.didPan(sender: sender)
    }
}

extension ClipInformationTransitioningController: ClipInformationAnimatorDelegate {
    // MARK: - ClipInformationAnimatorDelegate

    func clipInformationAnimatorDelegate(_ animator: ClipInformationAnimator, didComplete: Bool) {
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
            return ClipInformationPresentationAnimator(delegate: self)

        default:
            return nil
        }
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch self.transitionMode {
        case .custom:
            return ClipInformationDismissalAnimator(delegate: self)

        default:
            return nil
        }
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            self.presentationInteractiveAnimator = ClipInformationInteractivePresentationAnimator(logger: self.logger)
            return self.presentationInteractiveAnimator

        default:
            return nil
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            self.dismissalInteractiveAnimator = ClipInformationInteractiveDismissalAnimator(logger: self.logger)
            return self.dismissalInteractiveAnimator

        default:
            return nil
        }
    }
}
