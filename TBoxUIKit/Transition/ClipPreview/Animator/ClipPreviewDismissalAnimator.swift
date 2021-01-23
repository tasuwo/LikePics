//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewDismissalAnimator: NSObject {
    static let transitionDuration: TimeInterval = 0.2

    private weak var delegate: ClipPreviewAnimatorDelegate?
    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    // MARK: - Lifecycle

    init(delegate: ClipPreviewAnimatorDelegate, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.delegate = delegate
        self.fallbackAnimator = fallbackAnimator
    }
}

extension ClipPreviewDismissalAnimator: ClipPreviewAnimator {}

extension ClipPreviewDismissalAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let fromPage = from.animatingPage(self),
            let fromItemId = from.currentItemId(self),
            let fromImageView = fromPage.imageView,
            let fromImage = fromImageView.image,
            let targetCell = to.animatingCell(self),
            let toViewBaseView = to.baseView(self)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.transitionDuration, isInteractive: false)
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.insertSubview(to.view, belowSubview: from.view)

        let fromViewBackgroundView = UIView()
        fromViewBackgroundView.frame = toViewBaseView.frame
        fromViewBackgroundView.backgroundColor = from.view.backgroundColor
        from.view.backgroundColor = .clear
        toViewBaseView.addSubview(fromViewBackgroundView)

        let animatingView = UIView()
        ClipCollectionViewCell.setupAppearance(shadowView: animatingView)
        animatingView.frame = from.clipPreviewAnimator(self, frameOnContainerView: containerView)
        toViewBaseView.insertSubview(animatingView, aboveSubview: fromViewBackgroundView)

        let animatingImageView = UIImageView(image: fromImage)
        ClipCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = animatingView.bounds
        animatingView.addSubview(animatingImageView)

        targetCell.isHidden = true
        fromImageView.isHidden = true

        from.navigationController?.navigationBar.alpha = 1.0
        fromViewBackgroundView.alpha = 1.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            fromImageView.isHidden = false
            targetCell.isHidden = false
            fromViewBackgroundView.removeFromSuperview()
            animatingView.removeFromSuperview()
            from.view.backgroundColor = fromViewBackgroundView.backgroundColor
            transitionContext.completeTransition(true)
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = 0
        cornerAnimation.toValue = ClipCollectionViewCell.cornerRadius
        animatingView.layer.cornerRadius = ClipCollectionViewCell.cornerRadius
        animatingView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))
        animatingImageView.layer.cornerRadius = ClipCollectionViewCell.cornerRadius
        animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseIn]
        ) {
            animatingView.frame = to.clipPreviewAnimator(self, frameOnContainerView: containerView, forItemId: fromItemId)
            animatingImageView.frame = animatingView.bounds

            from.view.alpha = 0
            fromViewBackgroundView.alpha = 0
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.clipPreviewAnimator(self, didComplete: transitionCompleted)
    }
}
