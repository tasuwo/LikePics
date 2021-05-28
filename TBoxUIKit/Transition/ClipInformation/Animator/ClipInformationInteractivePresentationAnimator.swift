//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

class ClipInformationInteractivePresentationAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingImageView: UIImageView
        let toViewBackgroundColor: UIColor?
        let postproces: () -> Void
    }

    struct FinishAnimationParameters {
        let from: ClipInformationPresentingAnimatorDataSource & UIViewController
        let to: ClipInformationPresentedAnimatorDataSource & UIViewController
        let innerContext: InnerContext
    }

    private static let toViewStartingAlpha: CGFloat = 0.0
    private static let toViewFinalAlpha: CGFloat = 1.0
    private static let fromComponentsStartingAlpha: CGFloat = 1.0
    private static let fromComponentsFinalAlpha: CGFloat = 0.0

    private static let cancelAnimateDuration: TimeInterval = 0.2
    private static let endAnimateDuration: TimeInterval = 0.2
    private static let fallbackAnimateDuration: TimeInterval = 0.2

    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    private var logger: Loggable
    private var innerContext: InnerContext?
    private var shouldEndImmediately = false

    private let lock = NSLock()

    // MARK: - Lifecycle

    init(logger: Loggable, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.logger = logger
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
        let range = fromFrame.midY - toFrame.midY
        return fromFrame.midY - (percent * range)
    }

    private static func calcToViewAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let percentAlpha = self.calcProgress(in: view, verticalDelta: verticalDelta)
        let alphaRange = Self.toViewStartingAlpha - Self.toViewFinalAlpha
        return Self.toViewStartingAlpha - (percentAlpha * alphaRange)
    }

    private static func calcFromComponentsAlpha(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let percentAlpha = min(self.calcProgress(in: view, verticalDelta: verticalDelta) * 3, 1)
        let alphaRange = Self.fromComponentsStartingAlpha - Self.fromComponentsFinalAlpha
        return Self.fromComponentsStartingAlpha - (percentAlpha * alphaRange)
    }

    // MARK: Internal

    func didPan(sender: UIPanGestureRecognizer) {
        guard let innerContext = self.innerContext else {
            logger.write(ConsoleLog(level: .debug, message: "Ignored '\(sender.state.description)' gesture for ClipInformationView presentation", scope: .transition))
            shouldEndImmediately = sender.state.isContinuousGestureFinished
            return
        }

        let transitionContext = innerContext.transitionContext
        let containerView = transitionContext.containerView
        let initialImageFrame = innerContext.initialImageFrame
        let animatingImageView = innerContext.animatingImageView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentedAnimatorDataSource & UIViewController)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        // Calculation

        let finalImageFrame = to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y > 0 ? 0 : translation.y
        let progress = Self.calcProgress(in: from.view, verticalDelta: verticalDelta)
        let nextMidY = Self.calcNextMidY(in: from.view, fromFrame: initialImageFrame, toFrame: finalImageFrame, verticalDelta: verticalDelta)

        // Middle Animation

        from.componentsOverBaseView(self).forEach { $0.alpha = Self.calcFromComponentsAlpha(in: from.view, verticalDelta: verticalDelta) }
        to.view.alpha = Self.calcToViewAlpha(in: from.view, verticalDelta: verticalDelta)

        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(x: initialAnchorPoint.x, y: nextMidY)

        animatingImageView.center = nextAnchorPoint

        transitionContext.updateInteractiveTransition(progress)

        // End Animation

        logger.write(ConsoleLog(level: .debug, message: "Handle '\(sender.state.description)' gesture for ClipInformationView presentation", scope: .transition))

        switch sender.state {
        case .ended, .cancelled, .failed, .recognized:
            let params = FinishAnimationParameters(from: from, to: to, innerContext: innerContext)

            let velocity = sender.velocity(in: from.view)
            let scrollToDown = velocity.y > 0
            let releaseBelowInitialPosition = nextAnchorPoint.y > initialAnchorPoint.y

            if scrollToDown || releaseBelowInitialPosition {
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

        logger.write(ConsoleLog(level: .debug, message: "Start cancel animation for ClipInformationView presentation", scope: .transition))

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.cancelAnimateDuration)
        CATransaction.setCompletionBlock {
            params.to.view.removeFromSuperview()

            params.innerContext.postproces()

            params.innerContext.transitionContext.cancelInteractiveTransition()
            params.innerContext.transitionContext.completeTransition(false)
            self.innerContext = nil
            self.lock.unlock()

            self.logger.write(ConsoleLog(level: .debug, message: "Finish cancel animation for ClipInformationView presentation", scope: .transition))
        }

        UIView.animate(
            withDuration: Self.cancelAnimateDuration,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            params.innerContext.animatingImageView.frame = params.innerContext.initialImageFrame
            params.to.view.alpha = 0.0
        }

        UIView.animate(
            withDuration: Self.cancelAnimateDuration / 3,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            params.from.componentsOverBaseView(self).forEach { $0.alpha = 1.0 }
        }

        CATransaction.commit()
    }

    private func startEndAnimation(params: FinishAnimationParameters) {
        lock.lock()

        logger.write(ConsoleLog(level: .debug, message: "Start end animation for ClipInformationView presentation", scope: .transition))

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.endAnimateDuration)
        CATransaction.setCompletionBlock {
            params.innerContext.postproces()

            params.innerContext.transitionContext.finishInteractiveTransition()
            params.innerContext.transitionContext.completeTransition(true)
            self.innerContext = nil
            self.lock.unlock()

            self.logger.write(ConsoleLog(level: .debug, message: "Finish end animation for ClipInformationView presentation", scope: .transition))
        }

        UIView.animate(
            withDuration: Self.endAnimateDuration,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            let containerView = params.innerContext.transitionContext.containerView
            params.innerContext.animatingImageView.frame = params.to.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
            params.to.view.alpha = 1.0
        }

        UIView.animate(
            withDuration: Self.endAnimateDuration / 3,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            params.from.componentsOverBaseView(self).forEach { $0.alpha = 0.0 }
        }

        CATransaction.commit()
    }
}

extension ClipInformationInteractivePresentationAnimator: ClipInformationAnimator {}

extension ClipInformationInteractivePresentationAnimator: UIViewControllerInteractiveTransitioning {
    // MARK: - UIViewControllerInteractiveTransitioning

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        lock.lock(); defer { lock.unlock() }

        logger.write(ConsoleLog(level: .debug, message: "Start transition for ClipInformationView presentation", scope: .transition))

        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipInformationPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipInformationPresentedAnimatorDataSource & UIViewController),
            let targetInformationView = to.animatingInformationView(self),
            let selectedPreviewView = from.animatingPreviewView(self),
            let selectedImageView = selectedPreviewView.imageView,
            let selectedImage = selectedImageView.image,
            let fromViewBaseView = from.baseView(self)
        else {
            logger.write(ConsoleLog(level: .debug, message: "Start fallback transition for ClipInformationView presentation", scope: .transition))
            fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        /*
         アニメーション時、画像を Tab/Navigation Bar の裏側に回り込ませることで、自然なアニメーションを実現する
         このために、以下のような構成を取る

         ポイントは以下
         - ToViewはFromViewの裏に配置する
         - ToViewが見えるよう、FromViewの背景色をclearに設定する
         - containerViewの背景色は、ToViewの背景色と合わせておく

         +-+            +-+  +-+
         | |       +-+  | |  | |
         +-+       | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |        | |  | |  | |
          |   +-+  | |  | |  | |
          |   | |  +-+  | |  | |
          |   +-+   |   +-+  +-+
          |    |    |    |    |
          |    |    |    |    +--- ToView
          |    |    |    +-------- FromViewBaseView
          |    |    +------------- AnimatingImageView
          |    +------------------ ToolBAr
          +----------------------- NavigationBar
         |     |          |
         +--+--+          |
         |  |             |
         |  +--------------------- Components over base view
         |                |
         +---------+------+
                   |
                   +-------------- FromView
         */

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.backgroundColor = to.view.backgroundColor
        containerView.insertSubview(to.view, belowSubview: from.view)

        let initialImageFrame = from.clipInformationAnimator(self, imageFrameOnContainerView: containerView)
        let animatingImageView = UIImageView(image: selectedImage)
        animatingImageView.frame = initialImageFrame

        // Preprocess

        let toViewBackgroundColor = to.view.backgroundColor

        targetInformationView.imageView.isHidden = true
        selectedImageView.isHidden = true
        selectedPreviewView.isLoadingIndicatorHidden = true
        from.view.backgroundColor = .clear

        fromViewBaseView.insertSubview(animatingImageView, aboveSubview: to.view)

        let postprocess = {
            from.view.isUserInteractionEnabled = true
            targetInformationView.imageView.isHidden = false
            selectedImageView.isHidden = false
            selectedPreviewView.isLoadingIndicatorHidden = false
            from.view.backgroundColor = toViewBackgroundColor

            animatingImageView.removeFromSuperview()
        }

        to.view.alpha = 0

        let innerContext = InnerContext(
            transitionContext: transitionContext,
            initialImageFrame: initialImageFrame,
            animatingImageView: animatingImageView,
            toViewBackgroundColor: toViewBackgroundColor,
            postproces: postprocess
        )

        if self.shouldEndImmediately {
            self.shouldEndImmediately = false
            let params = FinishAnimationParameters(from: from,
                                                   to: to,
                                                   innerContext: innerContext)
            lock.unlock()
            logger.write(ConsoleLog(level: .debug, message: "Immediately ended transition for ClipInformationView presentation", scope: .transition))
            startEndAnimation(params: params)
            return
        }

        self.innerContext = innerContext
    }
}
