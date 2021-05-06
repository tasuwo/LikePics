//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
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
            let fromImageView = fromPage.imageView,
            let fromImage = fromImageView.image,
            let toCell = to.animatingCell(self),
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

        let animatingImageView = UIImageView(image: fromImage)
        animatingImageView.layer.cornerRadius = to.animatingCellCornerRadius(self)
        animatingImageView.contentMode = .scaleAspectFill
        animatingImageView.clipsToBounds = true
        animatingImageView.frame = from.clipPreviewAnimator(self, frameOnContainerView: containerView)
        animatingImageView.layer.cornerCurve = .continuous
        animatingImageView.layer.masksToBounds = true

        // Display Cell

        to.displayAnimatingCell(self)

        // Preprocess

        from.view.backgroundColor = .clear
        toCell.alpha = 0
        fromImageView.isHidden = true

        toViewBaseView.addSubview(fromViewBackgroundView)
        toViewBaseView.insertSubview(animatingImageView, aboveSubview: fromViewBackgroundView)

        let postprocess = { (completion: @escaping () -> Void) in
            from.view.backgroundColor = fromViewBackgroundView.backgroundColor
            fromImageView.isHidden = false

            UIView.animate(withDuration: 0.15, animations: {
                toCell.alpha = 1
            }, completion: { _ in
                animatingImageView.alpha = 0
                fromViewBackgroundView.removeFromSuperview()
                animatingImageView.removeFromSuperview()
                completion()
            })
        }

        from.navigationController?.navigationBar.alpha = 1.0
        fromViewBackgroundView.alpha = 1.0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            postprocess {
                transitionContext.completeTransition(true)
            }
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = 0
        cornerAnimation.toValue = to.animatingCellCornerRadius(self)
        animatingImageView.layer.cornerRadius = to.animatingCellCornerRadius(self)
        animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseIn]
        ) {
            if from.isCurrentItemPrimary(self) {
                let frame = to.primaryThumbnailFrame(self, on: containerView)
                animatingImageView.frame = frame
            } else {
                let frame = to.animatingCellFrame(self, on: containerView)
                animatingImageView.frame = frame.scaled(0.2)
                animatingImageView.alpha = 0
            }

            from.view.alpha = 0
            fromViewBackgroundView.alpha = 0
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.clipPreviewAnimator(self, didComplete: transitionCompleted)
    }
}
