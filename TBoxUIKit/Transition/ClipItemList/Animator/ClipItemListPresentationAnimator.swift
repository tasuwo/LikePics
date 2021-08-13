//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipItemListPresentationAnimator: NSObject {
    static let transitionDuration: TimeInterval = 0.23

    private weak var delegate: ClipItemListAnimatorDelegate?
    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    // MARK: - Initializers

    init(delegate: ClipItemListAnimatorDelegate, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.delegate = delegate
        self.fallbackAnimator = fallbackAnimator
    }
}

extension ClipItemListPresentationAnimator: ClipItemListAnimator {}

extension ClipItemListPresentationAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipItemListPresentable & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipItemListPresenting & UIViewController),
            let fromPreviewView = from.previewView(self),
            let fromImageView = fromPreviewView.imageView,
            let fromImage = fromImageView.image,
            let previewingClipItem = from.previewingClipItem(self),
            let toCell = to.animatingCell(self, id: previewingClipItem.cellIdentity, needsScroll: true),
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
        animatingImageView.frame = from.clipItemListAnimator(self, imageFrameOnContainerView: containerView)
        animatingImageView.layer.cornerCurve = .continuous
        animatingImageView.layer.masksToBounds = true

        // Display Cell

        to.displayAnimatingCell(self, id: previewingClipItem.cellIdentity)

        // Preprocess

        from.view.backgroundColor = .clear
        // HACK: subViewが遅れて追加されるとalphaが効かないようなので、alphaではなくisHiddenを利用する
        toCell.isHidden = true
        fromImageView.isHidden = true
        fromPreviewView.isLoadingIndicatorHidden = true

        toViewBaseView.addSubview(fromViewBackgroundView)
        toViewBaseView.insertSubview(animatingImageView, aboveSubview: fromViewBackgroundView)

        let postprocess = { (completion: @escaping () -> Void) in
            from.view.backgroundColor = fromViewBackgroundView.backgroundColor
            fromImageView.isHidden = false
            fromPreviewView.isLoadingIndicatorHidden = false

            UIView.animate(withDuration: 0.15, animations: {
                toCell.isHidden = false
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
            let frame = to.thumbnailFrame(self, id: previewingClipItem.cellIdentity, needsScroll: false, on: containerView)
            animatingImageView.frame = frame

            from.view.alpha = 0
            fromViewBackgroundView.alpha = 0
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.clipItemListAnimatorDelegate(self, didComplete: transitionCompleted)
    }
}
