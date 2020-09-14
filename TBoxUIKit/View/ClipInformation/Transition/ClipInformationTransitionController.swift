//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationTransitionControllerProtocol {
    var isInteractiveTransitioning: Bool { get }
    func beginInteractiveTransition()
    func endInteractiveTransition()
    func didPan(sender: UIPanGestureRecognizer)
}

public class ClipInformationTransitioningController: NSObject {
    var isInteractive: Bool = false
    let interactiveAnimator = ClipInformationInteractiveDismissalAnimator()
}

extension ClipInformationTransitioningController: ClipInformationTransitionControllerProtocol {
    // MARK: - ClipInformationTransitionControllerProtocol

    public var isInteractiveTransitioning: Bool {
        return self.isInteractive
    }

    public func beginInteractiveTransition() {
        self.isInteractive = true
    }

    public func endInteractiveTransition() {
        self.isInteractive = false
    }

    public func didPan(sender: UIPanGestureRecognizer) {
        self.interactiveAnimator.didPan(sender: sender)
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

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactiveAnimator
    }
}
