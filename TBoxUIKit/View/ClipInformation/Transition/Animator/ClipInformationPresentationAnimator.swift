//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipInformationPresentationAnimator: NSObject {}

extension ClipInformationPresentationAnimator: ClipInformationAnimator {}

extension ClipInformationPresentationAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentedAnimatorDataSource & UIViewController),
            let targetInformationView = to.animatingInformationView(self),
            let selectedPage = from.animatingPageView(self),
            let selectedImageView = selectedPage.imageView,
            let selectedImage = selectedImageView.image
        else {
            transitionContext.completeTransition(false)
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        targetInformationView.imageView.isHidden = true
        selectedImageView.isHidden = true

        containerView.backgroundColor = .clear
        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingImageView = UIImageView(image: selectedImage)
        animatingImageView.frame = from.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
        containerView.addSubview(animatingImageView)

        to.view.alpha = 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            targetInformationView.imageView.isHidden = false
            selectedImageView.isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext)) {
            animatingImageView.frame = to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
            from.view.alpha = 0
            to.view.alpha = 1.0
        }

        CATransaction.commit()
    }
}
