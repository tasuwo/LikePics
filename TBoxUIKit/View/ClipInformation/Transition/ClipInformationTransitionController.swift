//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public enum ClipInformationTransitioningType {
    case dismiss
    case present
}

public protocol ClipInformationTransitionControllerProtocol {
    var isInteractiveTransitioning: Bool { get }
    func beginInteractiveTransition(_ type: ClipInformationTransitioningType)
    func endInteractiveTransition()
    func didPan(sender: UIPanGestureRecognizer)
}

public class ClipInformationTransitioningController: NSObject {
    var isInteractive: Bool = false
    var currentInteractiveTransitionType: ClipInformationTransitioningType?
    let presentationInteractiveAnimator = ClipInformationInteractivePresentationAnimator()
    let dismissalInteractiveAnimator = ClipInformationInteractiveDismissalAnimator()
}

extension ClipInformationTransitioningController: ClipInformationTransitionControllerProtocol {
    // MARK: - ClipInformationTransitionControllerProtocol

    public var isInteractiveTransitioning: Bool {
        return self.isInteractive
    }

    public func beginInteractiveTransition(_ type: ClipInformationTransitioningType) {
        self.currentInteractiveTransitionType = nil
        self.currentInteractiveTransitionType = type
        self.isInteractive = true
    }

    public func endInteractiveTransition() {
        self.isInteractive = false
    }

    public func didPan(sender: UIPanGestureRecognizer) {
        switch self.currentInteractiveTransitionType {
        case .present:
            self.presentationInteractiveAnimator.didPan(sender: sender)

        case .dismiss:
            self.dismissalInteractiveAnimator.didPan(sender: sender)

        case .none:
            break
        }
    }
}

extension ClipInformationTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return ClipInformationPresentationAnimator()
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ClipInformationDismissalAnimator()
    }

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.presentationInteractiveAnimator
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.dismissalInteractiveAnimator
    }
}
