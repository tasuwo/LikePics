//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewPresentTransitionAnimator: NSObject {}

extension ClipPreviewPresentTransitionAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.38
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? ClipPreviewPresentingViewController,
            let to = transitionContext.viewController(forKey: .to) as? ClipPreviewPresentedViewController,
            let selectedIndex = from.collectionView(self).indexPathsForSelectedItems?.first,
            let selectedCell = from.collectionView(self).cellForItem(at: selectedIndex) as? ClipCollectionViewCell,
            let selectedImageView = selectedCell.primaryImageView,
            let selectedImage = selectedCell.primaryImageView.image
        else {
            transitionContext.completeTransition(false)
            return
        }

        let animatingImageView = UIImageView(image: selectedImage)
        ClipCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = selectedCell.convert(selectedImageView.frame, to: from.view)

        to.view.frame = transitionContext.finalFrame(for: to)
        to.view.alpha = 0
        to.collectionView(self).isHidden = true
        selectedImageView.isHidden = true

        containerView.addSubview(to.view)
        containerView.addSubview(animatingImageView)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {
            ClipCollectionViewCell.resetAppearance(imageView: animatingImageView)

            let cellDisplayedArea = to.view.frame.inset(by: to.view.safeAreaInsets)
            let frameOnCell = ClipPreviewCollectionViewCell.calcCenterizedFrame(ofImage: selectedImage, in: cellDisplayedArea)
            animatingImageView.frame = .init(origin: to.view.convert(frameOnCell.origin, to: containerView),
                                             size: frameOnCell.size)

            to.view.alpha = 1.0
        }, completion: { finished in
            selectedImageView.isHidden = false
            to.collectionView(self).isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
