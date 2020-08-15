//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewPresentationAnimator: NSObject {}

extension ClipPreviewPresentationAnimator: ClipPreviewAnimator {}

extension ClipPreviewPresentationAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let targetImageView = to.animatingPage(self),
            let selectedCell = from.animatingCell(self),
            let selectedImageView = selectedCell.primaryImageView,
            let selectedImage = selectedImageView.image
        else {
            transitionContext.completeTransition(false)
            return
        }

        targetImageView.isHidden = true
        selectedImageView.isHidden = true

        containerView.backgroundColor = .clear
        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingImageView = UIImageView(image: selectedImage)
        ClipsCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = selectedCell.convert(selectedImageView.frame, to: from.view)
        containerView.addSubview(animatingImageView)

        to.view.alpha = 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            targetImageView.isHidden = false
            selectedImageView.isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = 10
        cornerAnimation.toValue = 0
        animatingImageView.layer.cornerRadius = 0
        animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(withDuration: 0.2) {
            selectedCell.alpha = 0
        }

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext)) {
            animatingImageView.frame = to.clipPreviewAnimator(self, frameOnContainerView: containerView)
            from.view.alpha = 0
            to.view.alpha = 1.0
        }

        CATransaction.commit()
    }
}
