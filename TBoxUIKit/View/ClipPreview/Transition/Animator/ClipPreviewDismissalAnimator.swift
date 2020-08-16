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
            let fromPage = from.animatingPage(self),
            let fromImageView = fromPage.imageView,
            let fromImage = fromImageView.image,
            let targetCell = to.animatingCell(self)
        else {
            transitionContext.completeTransition(false)
            return
        }

        containerView.backgroundColor = .clear
        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingView = UIView()
        ClipsCollectionViewCell.setupAppearance(shadowView: animatingView, interfaceStyle: from.traitCollection.userInterfaceStyle)
        animatingView.frame = from.clipPreviewAnimator(self, frameOnContainerView: containerView)
        containerView.addSubview(animatingView)

        let animatingImageView = UIImageView(image: fromImage)
        ClipsCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = animatingView.bounds
        animatingView.addSubview(animatingImageView)

        targetCell.isHidden = true
        fromImageView.isHidden = true

        to.view.alpha = 0
        from.navigationController?.navigationBar.alpha = 1.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            fromImageView.isHidden = false
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
            animatingView.frame = to.clipPreviewAnimator(self, frameOnContainerView: containerView, forIndex: 0)
            animatingImageView.frame = animatingView.bounds

            to.view.alpha = 1.0
            from.view.alpha = 0
        }

        CATransaction.commit()
    }
}
