//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit
import os.log

@MainActor
class ClipItemInformationInteractiveDismissalAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingImageView: UIImageView
        let toViewBackgroundColor: UIColor?
        let postprocess: () -> Void
    }

    struct FinishAnimationParameters {
        let from: ClipItemInformationPresenting & UIViewController
        let to: ClipItemInformationPresentable & UIViewController
        let innerContext: InnerContext
    }

    private static let fromViewStartingAlpha: CGFloat = 1.0
    private static let fromViewFinalAlpha: CGFloat = 0.0
    private static let toComponentsStartingAlpha: CGFloat = 0.0
    private static let toComponentsFinalAlpha: CGFloat = 1.0

    private static let cancelAnimateDuration: Double = 0.15
    private static let endAnimateDuration: Double = 0.17
    private static let fallbackAnimateDuration: Double = 0.2

    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    private var innerContext: InnerContext?
    private var shouldEndImmediately = false
    private var logger = Logger(LogHandler.transition)

    private let lock = NSLock()

    // MARK: - Lifecycle

    init(fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.fallbackAnimator = fallbackAnimator
    }

    // MARK: - Methods

    // MARK: Calculation

    private static func calcProgress(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height * 2 / 3
        return min(abs(verticalDelta) / maximumDelta, 1.0)
    }

    private static func calcNextMidY(in view: UIView, fromFrame: CGRect, toFrame: CGRect, verticalDelta: CGFloat) -> CGFloat {
        let percent = self.calcProgress(in: view, verticalDelta: verticalDelta)
        let range = toFrame.midY - fromFrame.midY
        return fromFrame.midY + (percent * range)
    }

    private static func calcFromViewAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let percentAlpha = self.calcProgress(in: view, verticalDelta: verticalDelta)
        let alphaRange = Self.fromViewStartingAlpha - Self.fromViewFinalAlpha
        return Self.fromViewStartingAlpha - (percentAlpha * alphaRange)
    }

    private static func calcToComponentsAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let percentAlpha = self.calcProgress(in: view, verticalDelta: verticalDelta)
        let alphaRange = Self.toComponentsStartingAlpha - Self.toComponentsFinalAlpha
        return Self.toComponentsStartingAlpha - (percentAlpha * alphaRange)
    }

    // MARK: Internal

    func didPan(sender: UIPanGestureRecognizer) {
        guard let innerContext = self.innerContext else {
            logger.debug("Ignored '\(sender.state.description, privacy: .public)' gesture for ClipItemInformationView dismissal")
            shouldEndImmediately = sender.state.isContinuousGestureFinished
            return
        }

        let transitionContext = innerContext.transitionContext
        let containerView = transitionContext.containerView
        let initialImageFrame = innerContext.initialImageFrame
        let animatingImageView = innerContext.animatingImageView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipItemInformationPresenting & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipItemInformationPresentable & UIViewController)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        // Calculation

        let finalImageFrame = to.clipItemInformationAnimator(self, imageFrameOnContainerView: containerView)
        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y < 0 ? 0 : translation.y
        let progress = Self.calcProgress(in: from.view, verticalDelta: verticalDelta)
        let nextMidY = Self.calcNextMidY(in: from.view, fromFrame: initialImageFrame, toFrame: finalImageFrame, verticalDelta: verticalDelta)

        // Middle Animation

        to.componentsOverBaseView(self).forEach { $0.alpha = Self.calcToComponentsAlpha(in: from.view, verticalDelta: verticalDelta) }
        from.view.alpha = Self.calcFromViewAlpha(in: from.view, verticalDelta: verticalDelta)

        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(x: initialAnchorPoint.x, y: nextMidY)

        animatingImageView.center = nextAnchorPoint

        transitionContext.updateInteractiveTransition(progress)

        // End Animation

        logger.debug("Handle '\(sender.state.description, privacy: .public)' gesture for ClipItemInformationView dismissal")

        switch sender.state {
        case .ended, .cancelled, .failed, .recognized:
            let params = FinishAnimationParameters(from: from, to: to, innerContext: innerContext)

            let velocity = sender.velocity(in: from.view)
            let scrollToUp = velocity.y < 0
            let releaseAboveInitialPosition = nextAnchorPoint.y < initialAnchorPoint.y

            if scrollToUp || releaseAboveInitialPosition {
                startCancelAnimation(params: params)
            } else {
                startEndAnimation(params: params)
            }

        case .possible, .began, .changed:
            // NOP
            break

        @unknown default:
            // NOP
            break
        }
    }

    // MARK: Animation

    private func startCancelAnimation(params: FinishAnimationParameters) {
        lock.lock()

        logger.debug("Start cancel animation for ClipItemInformationView dismissal")

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.cancelAnimateDuration)
        CATransaction.setCompletionBlock {
            params.to.view.removeFromSuperview()

            params.innerContext.postprocess()

            params.innerContext.transitionContext.cancelInteractiveTransition()
            params.innerContext.transitionContext.completeTransition(false)
            self.innerContext = nil
            self.lock.unlock()

            self.logger.debug("Finish cancel animation for ClipItemInformationView dismissal")
        }

        UIView.likepics_animate(
            withDuration: Self.cancelAnimateDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                params.innerContext.animatingImageView.frame = params.innerContext.initialImageFrame
                params.from.view.alpha = 1.0
            }
        )

        UIView.likepics_animate(
            withDuration: Self.cancelAnimateDuration / 3,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            params.to.componentsOverBaseView(self).forEach { $0.alpha = 0.0 }
        }

        CATransaction.commit()
    }

    private func startEndAnimation(params: FinishAnimationParameters) {
        lock.lock()

        logger.debug("Start end animation for ClipItemInformationView dismissal")

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.endAnimateDuration)
        CATransaction.setCompletionBlock {
            params.innerContext.postprocess()

            params.innerContext.transitionContext.finishInteractiveTransition()
            params.innerContext.transitionContext.completeTransition(true)
            self.innerContext = nil
            self.lock.unlock()

            self.logger.debug("Finish end animation for ClipItemInformationView dismissal")
        }

        UIView.likepics_animate(
            withDuration: Self.endAnimateDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                let containerView = params.innerContext.transitionContext.containerView
                params.innerContext.animatingImageView.frame = params.to.clipItemInformationAnimator(self, imageFrameOnContainerView: containerView)
                params.from.view.alpha = 0.0
            }
        )

        UIView.likepics_animate(
            withDuration: Self.endAnimateDuration / 3,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            params.to.componentsOverBaseView(self).forEach { $0.alpha = 1.0 }
        }

        CATransaction.commit()
    }
}

extension ClipItemInformationInteractiveDismissalAnimator: ClipItemInformationAnimator {}

extension ClipItemInformationInteractiveDismissalAnimator: UIViewControllerInteractiveTransitioning {
    // MARK: - UIViewControllerInteractiveTransitioning

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        lock.lock()
        defer { lock.unlock() }

        logger.debug("Start transition for ClipItemInformationView dismissal")

        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipItemInformationPresenting & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipItemInformationPresentable & UIViewController),
            let fromInformationView = from.clipInformationView(self),
            let fromImageView = fromInformationView.imageView,
            let fromImage = fromImageView.image,
            let targetPreviewView = to.previewView(self),
            let toViewBaseView = to.baseView(self)
        else {
            logger.debug("Start fallback transition for ClipItemInformationView dismissal")
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        guard let infoViewingClipItem = from.clipItem(self),
            to.isPreviewing(self, clipItem: infoViewingClipItem) == true
        else {
            logger.debug("Start fallback transition for ClipItemInformationView dismissal")
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        let toViewBackgroundColor = to.view.backgroundColor

        containerView.backgroundColor = toViewBackgroundColor
        containerView.insertSubview(to.view, aboveSubview: from.view)

        let initialImageFrame = from.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
        let animatingImageView = UIImageView(image: fromImage)
        animatingImageView.frame = initialImageFrame

        // Preprocess

        to.set(self, isUserInteractionEnabled: false)
        targetPreviewView.imageView.isHidden = true
        fromImageView.isHidden = true
        to.view.backgroundColor = .clear

        toViewBaseView.insertSubview(animatingImageView, aboveSubview: from.view)

        let postprocess = {
            to.set(self, isUserInteractionEnabled: true)
            targetPreviewView.imageView.isHidden = false
            fromImageView.isHidden = false
            to.view.backgroundColor = toViewBackgroundColor

            animatingImageView.removeFromSuperview()
        }

        to.componentsOverBaseView(self).forEach { $0.alpha = 0.0 }

        let innerContext = InnerContext(
            transitionContext: transitionContext,
            initialImageFrame: initialImageFrame,
            animatingImageView: animatingImageView,
            toViewBackgroundColor: toViewBackgroundColor,
            postprocess: postprocess
        )

        if self.shouldEndImmediately {
            self.shouldEndImmediately = false
            let params = FinishAnimationParameters(from: from, to: to, innerContext: innerContext)
            lock.unlock()
            logger.debug("Immediately ended transition for ClipItemInformationView dismissal")
            startEndAnimation(params: params)
            return
        }

        self.innerContext = innerContext
    }
}
