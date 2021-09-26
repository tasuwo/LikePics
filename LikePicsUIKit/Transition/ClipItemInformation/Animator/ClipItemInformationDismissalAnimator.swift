//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipItemInformationDismissalAnimator: NSObject {
    private static let transitionDuration: TimeInterval = 0.15

    private weak var delegate: AnimatorDelegate?
    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    // MARK: - Initializers

    init(delegate: AnimatorDelegate, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.delegate = delegate
        self.fallbackAnimator = fallbackAnimator
    }
}

extension ClipItemInformationDismissalAnimator: ClipItemInformationAnimator {}

extension ClipItemInformationDismissalAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipItemInformationPresenting & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipItemInformationPresentable & UIViewController),
            let fromInformationView = from.clipInformationView(self),
            let fromImageView = fromInformationView.imageView,
            let fromImage = fromImageView.image,
            let targetPreviewView = to.previewView(self)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.transitionDuration, isInteractive: false)
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingView = UIView()
        animatingView.frame = from.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
        containerView.addSubview(animatingView)

        let animatingImageView = UIImageView(image: fromImage)
        animatingImageView.frame = animatingView.bounds
        animatingView.addSubview(animatingImageView)

        targetPreviewView.imageView.isHidden = true
        fromImageView.isHidden = true

        to.view.alpha = 0
        from.navigationController?.navigationBar.alpha = 1.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            fromImageView.isHidden = false
            targetPreviewView.imageView.isHidden = false
            animatingView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            animatingView.frame = to.clipItemInformationAnimator(self, imageFrameOnContainerView: containerView)
            animatingImageView.frame = animatingView.bounds

            to.view.alpha = 1.0
            from.view.alpha = 0
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.animator(self, didComplete: transitionCompleted)
    }
}
