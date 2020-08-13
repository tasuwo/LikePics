//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewTransitionControllerProtocol {
    var isInteractiveTransitioning: Bool { get }
    func beginInteractiveTransition()
    func endInteractiveTransition()
    func didPan(sender: UIPanGestureRecognizer)
}

public class ClipPreviewTransitioningController: NSObject {
    var isInteractive: Bool = false
    let interactiveAnimator = ClipPreviewInteractiveDismissalAnimator()
}

extension ClipPreviewTransitioningController: ClipPreviewTransitionControllerProtocol {
    // MARK: - ClipPreviewTransitionControllerProtocol

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

extension ClipPreviewTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return ClipPreviewPresentationAnimator()
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ClipPreviewDismissalAnimator()
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactiveAnimator
    }
}

extension ClipPreviewTransitioningController: UINavigationControllerDelegate {
    // MARK: - UINavigationControllerDelegate

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        switch operation {
        case .push:
            return ClipPreviewPresentationAnimator()
        case .pop:
            return ClipPreviewDismissalAnimator()
        default:
            return nil
        }
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard self.isInteractive else { return nil }
        return self.interactiveAnimator
    }
}
