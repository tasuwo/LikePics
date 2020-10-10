//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

class ClipInformationInteractivePresentationAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingView: UIView
        let animatingImageView: UIImageView
    }

    private static let startingAlpha: CGFloat = 1.0
    private static let finalAlpha: CGFloat = 0

    private static let cancelAnimateDuration: Double = 0.25
    private static let endAnimateDuration: Double = 0.25

    private var logger: TBoxLoggable
    private var innerContext: InnerContext?
    private var shouldEndImmediately: Bool = false

    // MARK: - Lifecycle

    init(logger: TBoxLoggable) {
        self.logger = logger
    }

    // MARK: - Methods

    // MARK: Calculation

    private static func calcProgress(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height * 2 / 3
        return min(abs(verticalDelta) / maximumDelta, 1.0)
    }

    private static func calcNextMidY(in view: UIView, fromFrame: CGRect, toFrame: CGRect, verticalDelta: CGFloat) -> CGFloat {
        let percent = self.calcProgress(in: view, verticalDelta: verticalDelta)
        let range = fromFrame.midY - toFrame.midY
        return fromFrame.midY - (percent * range)
    }

    private static func calcAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let percentAlpha = self.calcProgress(in: view, verticalDelta: verticalDelta)
        let alphaRange = Self.startingAlpha - Self.finalAlpha
        return Self.startingAlpha - (percentAlpha * alphaRange)
    }

    // MARK: Internal

    func didPan(sender: UIPanGestureRecognizer) {
        guard let innerContext = self.innerContext else {
            guard sender.state == .ended else {
                self.logger.write(ConsoleLog(level: .debug, message: "Interactive dismissal animator for ClipInformationView is not ready. Ignored gesture."))
                return
            }
            self.shouldEndImmediately = true
            return
        }

        let transitionContext = innerContext.transitionContext
        let containerView = transitionContext.containerView
        let initialImageFrame = innerContext.initialImageFrame
        let animatingView = innerContext.animatingView
        let animatingImageView = innerContext.animatingImageView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentedAnimatorDataSource & UIViewController),
            let targetInformationView = to.animatingInformationView(self),
            let selectedPage = from.animatingPageView(self),
            let selectedImageView = selectedPage.imageView
        else {
            transitionContext.cancelInteractiveTransition()
            transitionContext.completeTransition(false)
            return
        }

        // Calculation

        let finalImageFrame = to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y > 0 ? 0 : translation.y
        let progress = Self.calcProgress(in: from.view, verticalDelta: verticalDelta)
        let nextMidY = Self.calcNextMidY(in: from.view, fromFrame: initialImageFrame, toFrame: finalImageFrame, verticalDelta: verticalDelta)

        // Middle Animation

        to.view.alpha = 1
        from.view.alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)

        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(x: initialAnchorPoint.x, y: nextMidY)

        animatingView.center = nextAnchorPoint
        animatingImageView.frame = animatingView.bounds

        transitionContext.updateInteractiveTransition(progress)

        // End Animation

        if sender.state == .ended {
            let velocity = sender.velocity(in: from.view)
            let scrollToDown = velocity.y > 0
            let releaseBelowInitialPosition = nextAnchorPoint.y > initialAnchorPoint.y
            if scrollToDown || releaseBelowInitialPosition {
                self.startCancelAnimation(hideViews: [to.view],
                                          presentViews: [from.view],
                                          hiddenViews: [targetInformationView.imageView, selectedImageView],
                                          innerContext: innerContext)
            } else {
                self.startEndAnimation(finalImageFrame: finalImageFrame,
                                       hideViews: [from.view],
                                       presentViews: [to.view],
                                       hiddenViews: [targetInformationView.imageView, selectedImageView],
                                       innerContext: innerContext)
            }
        }
    }

    // MARK: Animation

    private func startCancelAnimation(hideViews: [UIView?], presentViews: [UIView?], hiddenViews: [UIView], innerContext: InnerContext) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.cancelAnimateDuration)
        CATransaction.setCompletionBlock {
            hiddenViews.forEach { $0.isHidden = false }
            innerContext.animatingView.removeFromSuperview()
            innerContext.transitionContext.cancelInteractiveTransition()
            innerContext.transitionContext.completeTransition(false)
            self.innerContext = nil
        }

        UIView.animate(
            withDuration: Self.cancelAnimateDuration,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                innerContext.animatingView.frame = innerContext.initialImageFrame
                innerContext.animatingImageView.frame = innerContext.animatingView.bounds
                hideViews.forEach { $0?.alpha = 0 }
                presentViews.forEach { $0?.alpha = 1 }
            }
        )

        CATransaction.commit()
    }

    private func startEndAnimation(finalImageFrame: CGRect, hideViews: [UIView?], presentViews: [UIView?], hiddenViews: [UIView], innerContext: InnerContext) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.endAnimateDuration)
        CATransaction.setCompletionBlock {
            hiddenViews.forEach { $0.isHidden = false }
            innerContext.animatingView.removeFromSuperview()
            innerContext.transitionContext.finishInteractiveTransition()
            innerContext.transitionContext.completeTransition(true)
            self.innerContext = nil
        }

        UIView.animate(
            withDuration: Self.endAnimateDuration,
            delay: 0,
            options: [],
            animations: {
                innerContext.animatingView.frame = finalImageFrame
                innerContext.animatingImageView.frame = innerContext.animatingView.bounds
                hideViews.forEach { $0?.alpha = 0 }
                presentViews.forEach { $0?.alpha = 1 }
            }
        )

        CATransaction.commit()
    }
}

extension ClipInformationInteractivePresentationAnimator: ClipInformationAnimator {}

extension ClipInformationInteractivePresentationAnimator: UIViewControllerInteractiveTransitioning {
    // MARK: - UIViewControllerInteractiveTransitioning

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentedAnimatorDataSource & UIViewController),
            let targetInformationView = to.animatingInformationView(self),
            let selectedPage = from.animatingPageView(self),
            let selectedImageView = selectedPage.imageView,
            let selectedImage = selectedImageView.image
        else {
            transitionContext.cancelInteractiveTransition()
            transitionContext.completeTransition(false)
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.insertSubview(to.view, belowSubview: from.view)

        let initialImageFrame = from.clipInformationAnimator(self, imageFrameOnContainerView: containerView)

        let animatingView = UIView()
        animatingView.frame = initialImageFrame
        containerView.addSubview(animatingView)

        let animatingImageView = UIImageView(image: selectedImage)
        animatingImageView.frame = animatingView.bounds
        animatingView.addSubview(animatingImageView)

        targetInformationView.imageView.isHidden = true
        selectedImageView.isHidden = true

        let innerContext = InnerContext(
            transitionContext: transitionContext,
            initialImageFrame: initialImageFrame,
            animatingView: animatingView,
            animatingImageView: animatingImageView
        )

        if self.shouldEndImmediately {
            self.shouldEndImmediately = false
            let finalImageFrame = to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
            self.startEndAnimation(finalImageFrame: finalImageFrame,
                                   hideViews: [from.view],
                                   presentViews: [to.view],
                                   hiddenViews: [targetInformationView.imageView, selectedImageView],
                                   innerContext: innerContext)
            return
        }

        self.innerContext = innerContext
    }
}
