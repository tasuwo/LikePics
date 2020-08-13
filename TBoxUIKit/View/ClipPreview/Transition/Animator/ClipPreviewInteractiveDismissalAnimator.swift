//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewInteractiveDismissalAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingImageView: UIImageView
    }

    private static let startingImageScale: CGFloat = 1.0
    private static let finalImageScale: CGFloat = 0.5
    private static let startingAlpha: CGFloat = 1.0
    private static let finalAlpha: CGFloat = 0

    private var innerContext: InnerContext?

    // MARK: - Methods

    func didPan(sender: UIPanGestureRecognizer) {
        guard let innerContext = self.innerContext else { return }
        let transitionContext = innerContext.transitionContext
        let containerView = transitionContext.containerView
        let initialImageFrame = innerContext.initialImageFrame
        let animatingImageView = innerContext.animatingImageView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let fromPage = from.animatingPage(self),
            let fromImageView = fromPage.imageView,
            let toCell = to.animatingCell(self)
        else {
            innerContext.transitionContext.completeTransition(false)
            return
        }

        // Calculation

        let finalImageFrame = toCell.primaryImageView.convert(toCell.primaryImageView.frame, to: containerView)
        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y < 0 ? 0 : translation.y
        let scale = Self.calcScale(in: from.view, verticalDelta: verticalDelta)
        let percentComplete = 1 - scale
        let alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)

        // Middle Animation

        toCell.isHidden = true
        fromImageView.isHidden = true

        to.view.alpha = 1
        from.view.alpha = alpha

        animatingImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(x: initialAnchorPoint.x + translation.x,
                                      y: initialAnchorPoint.y + translation.y - ((1 - scale) * initialImageFrame.height / 2))
        animatingImageView.center = nextAnchorPoint

        transitionContext.updateInteractiveTransition(percentComplete)

        // End Animation

        if sender.state == .ended {
            let velocity = sender.velocity(in: from.view)
            let scrollToUp = velocity.y < 0
            let releaseAboveInitialPosition = nextAnchorPoint.y < initialAnchorPoint.y
            if scrollToUp || releaseAboveInitialPosition {
                self.startCancelAnimation(hideViews: [to.view], presentViews: [from.view], hiddenViews: [toCell, fromImageView], innerContext: innerContext)
            } else {
                self.startEndAnimation(finalImageFrame: finalImageFrame, hideViews: [from.view], presentViews: [to.view], hiddenViews: [toCell, fromImageView], innerContext: innerContext)
            }
        }
    }

    // MARK: Animation

    private func startCancelAnimation(hideViews: [UIView?], presentViews: [UIView?], hiddenViews: [UIView], innerContext: InnerContext) {
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                innerContext.animatingImageView.frame = innerContext.initialImageFrame
                hideViews.forEach { $0?.alpha = 0 }
                presentViews.forEach { $0?.alpha = 1 }
            },
            completion: { completed in
                hiddenViews.forEach { $0.isHidden = false }
                innerContext.animatingImageView.removeFromSuperview()
                innerContext.transitionContext.cancelInteractiveTransition()
                innerContext.transitionContext.completeTransition(!innerContext.transitionContext.transitionWasCancelled)
                self.innerContext = nil
            }
        )
    }

    private func startEndAnimation(finalImageFrame: CGRect, hideViews: [UIView?], presentViews: [UIView?], hiddenViews: [UIView], innerContext: InnerContext) {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [],
            animations: {
                innerContext.animatingImageView.frame = finalImageFrame
                hideViews.forEach { $0?.alpha = 0 }
                presentViews.forEach { $0?.alpha = 1 }
            }, completion: { completed in
                hiddenViews.forEach { $0.isHidden = false }
                innerContext.animatingImageView.removeFromSuperview()
                innerContext.transitionContext.completeTransition(!innerContext.transitionContext.transitionWasCancelled)
                self.innerContext = nil
            }
        )
    }

    // MARK: Calculation

    private static func calcScale(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height * 2 / 3
        let percentScale = min(abs(verticalDelta) / maximumDelta, 1.0)
        let scaleRange = Self.startingImageScale - Self.finalImageScale
        return Self.startingImageScale - (percentScale * scaleRange)
    }

    private static func calcAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height * 2 / 3
        let percentAlpha = min(abs(verticalDelta) / maximumDelta, 1.0)
        let alphaRange = Self.startingAlpha - Self.finalAlpha
        return Self.startingAlpha - (percentAlpha * alphaRange)
    }
}

extension ClipPreviewInteractiveDismissalAnimator: ClipPreviewAnimator {}

extension ClipPreviewInteractiveDismissalAnimator: UIViewControllerInteractiveTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let fromPage = from.animatingPage(self),
            let fromImageView = fromPage.imageView,
            let fromImage = fromImageView.image,
            let toCell = to.animatingCell(self)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let initialImageFrame = fromPage.scrollView.convert(fromPage.imageView.frame, to: containerView)

        let animatingImageView = UIImageView(image: fromImage)
        animatingImageView.contentMode = .scaleAspectFit
        animatingImageView.frame = initialImageFrame
        containerView.addSubview(animatingImageView)

        toCell.isHidden = true
        fromImageView.isHidden = true

        containerView.insertSubview(to.view, belowSubview: from.view)

        self.innerContext = .init(
            transitionContext: transitionContext,
            initialImageFrame: initialImageFrame,
            animatingImageView: animatingImageView
        )
    }
}
