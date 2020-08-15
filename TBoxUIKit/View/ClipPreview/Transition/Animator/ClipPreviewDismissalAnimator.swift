//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewDismissalAnimator: NSObject {}

extension ClipPreviewDismissalAnimator: ClipPreviewAnimator {}

extension ClipPreviewDismissalAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let visiblePage = from.animatingPage(self),
            let visibleImageView = visiblePage.imageView,
            let visibleImage = visibleImageView.image,
            let targetCell = to.animatingCell(self)
        else {
            transitionContext.completeTransition(false)
            return
        }

        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingView = UIView()
        ClipsCollectionViewCell.setupAppearance(shadowView: animatingView)
        animatingView.frame = visiblePage.scrollView.convert(visiblePage.imageView.frame, to: containerView)
        containerView.addSubview(animatingView)

        let animatingImageView = UIImageView(image: visibleImage)
        ClipsCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = animatingView.bounds
        animatingView.addSubview(animatingImageView)

        targetCell.isHidden = true
        visibleImageView.isHidden = true

        to.view.alpha = 0
        from.navigationController?.navigationBar.alpha = 1.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            visibleImageView.isHidden = false
            targetCell.isHidden = false
            animatingView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = 0
        cornerAnimation.toValue = ClipsCollectionViewCell.cornerRadius
        animatingView.layer.cornerRadius = ClipsCollectionViewCell.cornerRadius
        animatingView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))
        animatingImageView.layer.cornerRadius = ClipsCollectionViewCell.cornerRadius
        animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext)) {
            animatingView.frame = targetCell.primaryImageView.convert(targetCell.primaryImageView.frame, to: containerView)
            animatingImageView.frame = animatingView.bounds

            to.view.alpha = 1.0
            from.view.alpha = 0
        }

        CATransaction.commit()
    }
}
