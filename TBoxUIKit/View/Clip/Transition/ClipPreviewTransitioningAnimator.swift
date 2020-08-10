//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentingViewController: UIViewController {
    func collectionView(_ animator: ClipPreviewTransitioningAnimator) -> ClipCollectionView
}

public protocol ClipPreviewPresentedViewController: UIViewController {
    func collectionView(_ animator: ClipPreviewTransitioningAnimator) -> ClipPreviewCollectionView
}

public class ClipPreviewTransitioningAnimator: NSObject {
    // MARK: - Methods

    private func calcExpectedImageFrame(from image: UIImage, on finalFrame: CGSize) -> CGSize {
        return .init(width: finalFrame.width, height: finalFrame.width * (image.size.height / image.size.width))
    }
}

extension ClipPreviewTransitioningAnimator: UIViewControllerAnimatedTransitioning {
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

            let finalFrameSize = transitionContext.finalFrame(for: to).size
            let finalImageSize = self.calcExpectedImageFrame(from: selectedImage, on: finalFrameSize)
            animatingImageView.frame = .init(origin: .init(x: 0, y: finalFrameSize.height / 2 - finalImageSize.height / 2), size: finalImageSize)

            to.view.alpha = 1.0
        }, completion: { finished in
            selectedImageView.isHidden = false
            to.collectionView(self).isHidden = false
            animatingImageView.removeFromSuperview()
            transitionContext.completeTransition(true)
        })
    }
}
