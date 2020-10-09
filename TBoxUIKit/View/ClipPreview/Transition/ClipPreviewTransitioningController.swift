//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewTransitionControllerProtocol {
    var delegate: ClipPreviewTransitioningControllerDelegate? { get set }
    var dataSource: ClipPreviewTransitioningControllerDataSource? { get set }
    func didPan(sender: UIPanGestureRecognizer)
}

public class ClipPreviewTransitioningController: NSObject {
    private lazy var interactiveAnimator: ClipPreviewInteractiveDismissalAnimator = {
        let animator = ClipPreviewInteractiveDismissalAnimator()
        animator.delegate = self
        return animator
    }()

    public weak var delegate: ClipPreviewTransitioningControllerDelegate?
    public weak var dataSource: ClipPreviewTransitioningControllerDataSource?
}

extension ClipPreviewTransitioningController: ClipPreviewTransitionControllerProtocol {
    // MARK: - ClipPreviewTransitionControllerProtocol

    public func didPan(sender: UIPanGestureRecognizer) {
        self.interactiveAnimator.didPan(sender: sender)
    }
}

extension ClipPreviewTransitioningController: ClipPreviewAnimatorDelegate {
    // MARK: - ClipPreviewAnimatorDelegate

    func didFailToPresent(_ animator: ClipPreviewAnimator) {
        self.delegate?.didFailToPresent(self)
    }

    func didFailToDismiss(_ animator: ClipPreviewAnimator) {
        self.delegate?.didFailToDismiss(self)
    }
}

extension ClipPreviewTransitioningController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        let animator = ClipPreviewPresentationAnimator()
        animator.delegate = self
        return animator
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let dataSource = self.dataSource else { return nil }
        switch dataSource.dismissalMode {
        case .custom(interactive: false):
            let animator = ClipPreviewDismissalAnimator()
            animator.delegate = self
            return animator

        default:
            return nil
        }
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let dataSource = self.dataSource else { return nil }
        switch dataSource.dismissalMode {
        case .custom(interactive: true):
            return self.interactiveAnimator

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
        switch operation {
        case .push:
            return ClipPreviewPresentationAnimator()

        case .pop:
            guard let dataSource = self.dataSource else { return nil }
            switch dataSource.dismissalMode {
            case .custom(interactive: false):
                let animator = ClipPreviewDismissalAnimator()
                animator.delegate = self
                return animator

            default:
                return nil
            }

        default:
            return nil
        }
    }

    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let dataSource = self.dataSource else { return nil }
        switch dataSource.dismissalMode {
        case .custom(interactive: true):
            return self.interactiveAnimator

        default:
            return nil
        }
    }
}
