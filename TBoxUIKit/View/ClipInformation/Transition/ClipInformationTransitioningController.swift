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

public protocol ClipInformationPresenting: UIViewController {
    func didFailToPresent(_ controller: ClipInformationTransitioningController)
}

public protocol ClipInformationPresented: UIViewController {
    func didFailToDismiss(_ controller: ClipInformationTransitioningController)
}

public protocol ClipInformationTransitioningControllerProtocol: UIViewControllerTransitioningDelegate {
    var isInteractive: Bool { get }
    func set(presenting: ClipInformationPresenting)
    func set(presented: ClipInformationPresented)
    func beginTransition(_ mode: ClipInformationTransitionMode)
    func endTransition()
    func didPanForPresentation(sender: UIPanGestureRecognizer)
    func didPanForDismissal(sender: UIPanGestureRecognizer)
}

public class ClipInformationTransitioningController: NSObject {
    lazy var presentationInteractiveAnimator: ClipInformationInteractivePresentationAnimator = {
        let animator = ClipInformationInteractivePresentationAnimator()
        animator.delegate = self
        return animator
    }()

    lazy var dismissalInteractiveAnimator: ClipInformationInteractiveDismissalAnimator = {
        let animator = ClipInformationInteractiveDismissalAnimator()
        animator.delegate = self
        return animator
    }()

    public var isInteractive: Bool {
        guard case .custom(interactive: true) = self.transitionMode else { return false }
        return true
    }

    weak var presenting: ClipInformationPresenting?
    weak var presented: ClipInformationPresented?
    var transitionMode: ClipInformationTransitionMode = .initialValue
}

extension ClipInformationTransitioningController: ClipInformationTransitioningControllerProtocol {
    // MARK: - ClipInformationTransitioningControllerProtocol

    public func set(presenting: ClipInformationPresenting) {
        self.presenting = presenting
    }

    public func set(presented: ClipInformationPresented) {
        self.presented = presented
    }

    public func beginTransition(_ mode: ClipInformationTransitionMode) {
        self.transitionMode = mode
    }

    public func endTransition() {
        self.transitionMode = .initialValue
    }

    public func didPanForDismissal(sender: UIPanGestureRecognizer) {
        self.dismissalInteractiveAnimator.didPan(sender: sender)
    }

    public func didPanForPresentation(sender: UIPanGestureRecognizer) {
        self.presentationInteractiveAnimator.didPan(sender: sender)
    }
}

extension ClipInformationTransitioningController: ClipInformationPresentationAnimatorDelegate {
    // MARK: - ClipInformationPresentationAnimatorDelegate

    func didFailToPresent(_ animator: ClipInformationAnimator) {
        self.presenting?.didFailToPresent(self)
    }
}

extension ClipInformationTransitioningController: ClipInformationDismissalAnimatorDelegate {
    // MARK: - ClipInformationDismissalAnimatorDelegate

    func didFailToDismiss(_ animator: ClipInformationAnimator) {
        self.presented?.didFailToDismiss(self)
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
            let animator = ClipInformationPresentationAnimator()
            animator.delegate = self
            return animator

        default:
            return nil
        }
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch self.transitionMode {
        case .custom:
            let animator = ClipInformationDismissalAnimator()
            animator.delegate = self
            return animator

        default:
            return nil
        }
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            return self.presentationInteractiveAnimator

        default:
            return nil
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        switch self.transitionMode {
        case .custom(interactive: true):
            return self.dismissalInteractiveAnimator

        default:
            return nil
        }
    }
}
