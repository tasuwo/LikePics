//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewDismissTransitionAnimator: NSObject {}

extension ClipPreviewDismissTransitionAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? ClipPreviewPresentedViewController,
            let to = transitionContext.viewController(forKey: .to) as? ClipPreviewPresentingViewController,
            let visibleCell = from.collectionView(self).visibleCells.first as? ClipPreviewCollectionViewCell,
            let visibleImageView = visibleCell.imageView,
            let visibleImage = visibleImageView.image
        else {
            transitionContext.completeTransition(false)
            return
        }

        let animatingImageView = UIImageView(image: visibleImage)
        animatingImageView.contentMode = .scaleAspectFit
        animatingImageView.frame = visibleImageView.convert(visibleImageView.frame, to: containerView)

        to.view.frame = transitionContext.finalFrame(for: to)
        to.view.alpha = 0
        visibleImageView.isHidden = true

        containerView.addSubview(to.view)
        containerView.addSubview(animatingImageView)

        let targetCell = to.collectionView(self).visibleCells.first(where: {
            guard let cell = $0 as? ClipCollectionViewCell else { return false }
            return cell.primaryImage == visibleImage
        })! as! ClipCollectionViewCell
        targetCell.isHidden = true

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            ClipCollectionViewCell.setupAppearance(imageView: visibleImageView)

            animatingImageView.frame = targetCell.primaryImageView.convert(targetCell.primaryImageView.frame, to: containerView)

            to.view.alpha = 1.0
            from.view.alpha = 0
        }, completion: { finished in
            visibleImageView.isHidden = false
            targetCell.isHidden = false
            to.collectionView(self).isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
