//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipInformationDismissalAnimator: NSObject {}

extension ClipInformationDismissalAnimator: ClipInformationAnimator {}

extension ClipInformationDismissalAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let fromInformationView = from.animatingInformationView(self),
            let fromImageView = fromInformationView.imageView,
            let fromImage = fromImageView.image,
            let targetPage = to.animatingPageView(self)
        else {
            transitionContext.completeTransition(false)
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

        targetPage.imageView.isHidden = true
        fromImageView.isHidden = true

        to.view.alpha = 0
        from.navigationController?.navigationBar.alpha = 1.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            fromImageView.isHidden = false
            targetPage.imageView.isHidden = false
            animatingView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext)) {
            animatingView.frame = to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
            animatingImageView.frame = animatingView.bounds

            to.view.alpha = 1.0
            from.view.alpha = 0
        }

        CATransaction.commit()
    }
}
