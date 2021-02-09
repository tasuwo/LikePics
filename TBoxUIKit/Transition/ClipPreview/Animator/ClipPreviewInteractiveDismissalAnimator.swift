//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit

class ClipPreviewInteractiveDismissalAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingImageView: UIImageView
        let fromViewBackgroundView: UIView
        let postprocess: () -> Void
    }

    struct FinishAnimationParameters {
        let finalImageFrame: CGRect
        let currentCornerRadius: CGFloat
        let from: ClipPreviewPresentedAnimatorDataSource & UIViewController
        let to: ClipPreviewPresentingAnimatorDataSource & UIViewController
        let innerContext: InnerContext
    }

    private static let startingImageScale: CGFloat = 1.0
    private static let finalImageScale: CGFloat = 0.5

    private static let startingAlpha: CGFloat = 1.0
    private static let finalAlpha: CGFloat = 0

    private static let startingCornerRadius: CGFloat = 0
    private static let finalCornerRadius: CGFloat = 15

    private static let cancelAnimateDuration: TimeInterval = 0.15
    private static let endAnimateDuration: TimeInterval = 0.17
    private static let fallbackAnimateDuration: TimeInterval = 0.17

    private var logger: TBoxLoggable
    private var fallbackAnimator: FadeTransitionAnimatorProtocol
    private var innerContext: InnerContext?
    private var shouldEndImmediately: Bool = false

    // MARK: - Lifecycle

    init(logger: TBoxLoggable, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.logger = logger
        self.fallbackAnimator = fallbackAnimator
    }

    // MARK: - Methods

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

    private static func calcCornerRadius(in view: UIView, verticalDelta: CGFloat) -> CGFloat {
        let maximumDelta = view.bounds.height / 2
        let percentCornerRadius = min(abs(verticalDelta) / maximumDelta, 1.0)
        let cornerRadiusRange = Self.startingCornerRadius - Self.finalCornerRadius
        return Self.startingCornerRadius - (percentCornerRadius * cornerRadiusRange)
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
        let animatingImageView = innerContext.animatingImageView
        let fromViewBackgroundView = innerContext.fromViewBackgroundView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let fromPage = from.animatingPage(self),
            let fromItemId = from.currentItemId(self),
            let fromImageView = fromPage.imageView,
            let toCell = to.animatingCell(self, shouldAdjust: true)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        // Calculation

        let finalImageFrame = to.clipPreviewAnimator(self, frameOnContainerView: containerView, forItemId: fromItemId)
        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y < 0 ? 0 : translation.y
        let scale = Self.calcScale(in: from.view, verticalDelta: verticalDelta)
        let cornerRadius = Self.calcCornerRadius(in: from.view, verticalDelta: verticalDelta)

        // Middle Animation

        toCell.isHidden = true
        fromImageView.isHidden = true

        to.view.alpha = 1
        from.view.alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)
        fromViewBackgroundView.alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)

        animatingImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(x: initialAnchorPoint.x + translation.x,
                                      y: initialAnchorPoint.y + translation.y - ((1 - scale) * initialImageFrame.height / 2))
        animatingImageView.center = nextAnchorPoint
        animatingImageView.layer.cornerRadius = cornerRadius

        transitionContext.updateInteractiveTransition(1 - scale)

        // End Animation

        if sender.state == .ended {
            let params = FinishAnimationParameters(finalImageFrame: finalImageFrame,
                                                   currentCornerRadius: cornerRadius,
                                                   from: from,
                                                   to: to,
                                                   innerContext: innerContext)

            let velocity = sender.velocity(in: from.view)
            let scrollToUp = velocity.y < 0
            let releaseAboveInitialPosition = nextAnchorPoint.y < initialAnchorPoint.y
            if scrollToUp || releaseAboveInitialPosition {
                self.startCancelAnimation(params: params)
            } else {
                self.startEndAnimation(params: params)
            }
        }
    }

    // MARK: Animation

    private func startCancelAnimation(params: FinishAnimationParameters) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.cancelAnimateDuration)
        CATransaction.setCompletionBlock {
            params.to.view.removeFromSuperview()

            params.innerContext.postprocess()

            params.innerContext.transitionContext.cancelInteractiveTransition()
            params.innerContext.transitionContext.completeTransition(false)
            self.innerContext = nil
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = params.currentCornerRadius
        cornerAnimation.toValue = 0
        params.innerContext.animatingImageView.layer.cornerRadius = 0
        params.innerContext.animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(
            withDuration: Self.cancelAnimateDuration,
            delay: 0,
            options: [.curveEaseOut],
            animations: {
                params.innerContext.animatingImageView.frame = params.innerContext.initialImageFrame

                params.from.view.alpha = 1
                params.innerContext.fromViewBackgroundView.alpha = 1
            }
        )

        CATransaction.commit()
    }

    private func startEndAnimation(params: FinishAnimationParameters) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.endAnimateDuration)
        CATransaction.setCompletionBlock {
            params.innerContext.postprocess()

            params.innerContext.transitionContext.finishInteractiveTransition()
            params.innerContext.transitionContext.completeTransition(true)
            self.innerContext = nil
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = params.currentCornerRadius
        cornerAnimation.toValue = ClipCollectionViewCell.cornerRadius
        params.innerContext.animatingImageView.layer.cornerRadius = ClipCollectionViewCell.cornerRadius
        params.innerContext.animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(
            withDuration: Self.endAnimateDuration,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                params.innerContext.animatingImageView.frame = params.finalImageFrame

                params.from.view.alpha = 0
                params.innerContext.fromViewBackgroundView.alpha = 0
            }
        )

        CATransaction.commit()
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
            let fromItemId = from.currentItemId(self),
            let fromImageView = fromPage.imageView,
            let fromImage = fromImageView.image,
            let toCell = to.animatingCell(self, shouldAdjust: true),
            let toViewBaseView = to.baseView(self)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        /*
         アニメーション時、画像を Tab/Navigation Bar の裏側に回り込ませることで、自然なアニメーションを実現する
         このために、以下のような構成を取る

         +-+       +-+       +-+  +-+
         | |       | |       | |  | |
         +-+       +-+       | |  | |
                    |        | |  | |
                    |   +-+  | |  | |
                    |   | |  | |  | |
                    |   +-+  | |  | |
                    |    |   | |  | |
         +-+  +-+   |    |   | |  | |
         | |  | |   |    |   | |  | |
         +-+  +-+   |    |   +-+  +-+
          |    |    |    |    |    |
          |    |    |    |    |    +--- ToViewBaseView
          |    |    |    |    +-------- FromViewBackgroundView
          |    |    |    +------------- AnimatingImageView
          |    |    +------------------ NavigationBar
          |    +----------------------- TabBar
          |   |     |               |
          |   +--+--+               |
          |   |  |                  |
          |   |  +--------------------- Components over base view
          |   |                     |
          |   +---------+-----------+
          |             |
          |             +-------------- ToView
          |
          +---------------------------- FromView
         */

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        containerView.insertSubview(to.view, belowSubview: from.view)

        let fromViewBackgroundView = UIView()
        fromViewBackgroundView.frame = toViewBaseView.frame
        fromViewBackgroundView.backgroundColor = from.view.backgroundColor

        let initialImageFrame = from.clipPreviewAnimator(self, frameOnContainerView: containerView)
        let animatingImageView = UIImageView(image: fromImage)
        ClipCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = initialImageFrame
        animatingImageView.layer.cornerCurve = .continuous
        animatingImageView.layer.masksToBounds = true

        // Preprocess

        from.view.backgroundColor = .clear
        toCell.isHidden = true
        fromImageView.isHidden = true

        toViewBaseView.addSubview(fromViewBackgroundView)
        toViewBaseView.insertSubview(animatingImageView, aboveSubview: fromViewBackgroundView)

        let postprocess = {
            from.view.backgroundColor = fromViewBackgroundView.backgroundColor
            toCell.isHidden = false
            fromImageView.isHidden = false

            fromViewBackgroundView.removeFromSuperview()
            animatingImageView.removeFromSuperview()
        }

        let innerContext = InnerContext(
            transitionContext: transitionContext,
            initialImageFrame: initialImageFrame,
            animatingImageView: animatingImageView,
            fromViewBackgroundView: fromViewBackgroundView,
            postprocess: postprocess
        )

        if self.shouldEndImmediately {
            self.shouldEndImmediately = false
            let finalImageFrame = to.clipPreviewAnimator(self, frameOnContainerView: containerView, forItemId: fromItemId)
            let params = FinishAnimationParameters(finalImageFrame: finalImageFrame,
                                                   currentCornerRadius: 0,
                                                   from: from,
                                                   to: to,
                                                   innerContext: innerContext)
            self.startEndAnimation(params: params)
            return
        }

        self.innerContext = innerContext
    }
}
