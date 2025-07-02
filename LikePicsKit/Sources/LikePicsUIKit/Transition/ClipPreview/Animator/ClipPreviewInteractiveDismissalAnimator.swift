//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import UIKit
import os.log

class ClipPreviewInteractiveDismissalAnimator: NSObject {
    struct InnerContext {
        let transitionContext: UIViewControllerContextTransitioning
        let initialImageFrame: CGRect
        let animatingImageView: UIImageView
        let fromViewBackgroundView: UIView
        let postprocess: (ClipPreviewPresentable, @escaping () -> Void) -> Void
    }

    struct FinishAnimationParameters {
        enum DismissalType {
            case stickToThumbnail(thumbnailFrame: CGRect)
            case fadeout(cellFrame: CGRect)
        }

        let dismissalType: DismissalType
        let currentCornerRadius: CGFloat
        let finalCornerRadius: CGFloat
        let from: ClipPreviewPresenting & UIViewController
        let to: ClipPreviewPresentable & UIViewController
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

    private var logger = Logger(LogHandler.transition)
    private var fallbackAnimator: FadeTransitionAnimatorProtocol
    private var innerContext: InnerContext?
    private var shouldEndImmediately = false

    private let lock = NSLock()

    // MARK: - Lifecycle

    init(fallbackAnimator: FadeTransitionAnimatorProtocol) {
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
            logger.debug("Ignored '\(sender.state.description)' gesture for ClipPreviewPageView dismissal")
            shouldEndImmediately = sender.state.isContinuousGestureFinished
            return
        }

        let transitionContext = innerContext.transitionContext
        let containerView = transitionContext.containerView
        let initialImageFrame = innerContext.initialImageFrame
        let animatingImageView = innerContext.animatingImageView
        let fromViewBackgroundView = innerContext.fromViewBackgroundView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresenting & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentable & UIViewController),
            let previewingClipItem = from.previewingClipItem(self)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
            return
        }

        // Display Cell

        to.displayAnimatingCell(self, id: previewingClipItem.cellIdentity)
        // CollectionViewの再描画により元のセルのインスタンスが破棄されている可能性があるため、
        // 最新のセルのインスタンスを取得し直し、非表示にする
        // iPad にて Preview 表示後、アプリをバックグラウンド > フォアグラウンドにすると再現しやすい
        to.animatingCell(self, id: previewingClipItem.cellIdentity, needsScroll: true)?.alpha = 0

        // Calculation

        let translation = sender.translation(in: from.view)
        let verticalDelta = translation.y < 0 ? 0 : translation.y
        let scale = Self.calcScale(in: from.view, verticalDelta: verticalDelta)
        let cornerRadius = Self.calcCornerRadius(in: from.view, verticalDelta: verticalDelta)

        // Middle Animation

        to.view.alpha = 1
        from.view.alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)
        fromViewBackgroundView.alpha = Self.calcAlpha(in: from.view, verticalDelta: verticalDelta)

        animatingImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        let initialAnchorPoint = CGPoint(x: initialImageFrame.midX, y: initialImageFrame.midY)
        let nextAnchorPoint = CGPoint(
            x: initialAnchorPoint.x + translation.x,
            y: initialAnchorPoint.y + translation.y - ((1 - scale) * initialImageFrame.height / 2)
        )
        animatingImageView.center = nextAnchorPoint
        animatingImageView.layer.cornerRadius = cornerRadius
        animatingImageView.layer.cornerCurve = .continuous

        transitionContext.updateInteractiveTransition(1 - scale)

        // End Animation

        logger.debug("Handle '\(sender.state.description)' gesture for ClipPreviewPageView dismissal")

        switch sender.state {
        case .ended, .cancelled, .failed, .recognized:
            let dismissalType: FinishAnimationParameters.DismissalType
            if previewingClipItem.isItemPrimary {
                dismissalType = .stickToThumbnail(thumbnailFrame: to.thumbnailFrame(self, id: previewingClipItem.cellIdentity, needsScroll: false, on: containerView))
            } else {
                if to.isDisplayablePrimaryThumbnailOnly(self) {
                    dismissalType = .fadeout(cellFrame: to.animatingCellFrame(self, id: previewingClipItem.cellIdentity, needsScroll: false, on: containerView))
                } else {
                    dismissalType = .stickToThumbnail(thumbnailFrame: to.thumbnailFrame(self, id: previewingClipItem.cellIdentity, needsScroll: false, on: containerView))
                }
            }
            let params = FinishAnimationParameters(
                dismissalType: dismissalType,
                currentCornerRadius: cornerRadius,
                finalCornerRadius: to.animatingCellCornerRadius(self),
                from: from,
                to: to,
                innerContext: innerContext
            )

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

        logger.debug("Start cancel animation for ClipPreviewPageView dismissal")

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.cancelAnimateDuration)
        CATransaction.setCompletionBlock {
            params.innerContext.postprocess(params.to) {
                params.to.view.removeFromSuperview()

                params.innerContext.transitionContext.cancelInteractiveTransition()
                params.innerContext.transitionContext.completeTransition(false)
                self.innerContext = nil
                self.lock.unlock()

                self.logger.debug("Finish cancel animation for ClipPreviewPageView dismissal")
            }
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = params.currentCornerRadius
        cornerAnimation.toValue = 0
        params.innerContext.animatingImageView.layer.cornerRadius = 0
        params.innerContext.animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.likepics_animate(
            withDuration: Self.cancelAnimateDuration,
            bounce: 0.2,
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
        lock.lock()

        logger.debug("Start end animation for ClipPreviewPageView dismissal")

        CATransaction.begin()
        CATransaction.setAnimationDuration(Self.endAnimateDuration)
        CATransaction.setCompletionBlock {
            params.innerContext.postprocess(params.to) {
                params.innerContext.transitionContext.finishInteractiveTransition()
                params.innerContext.transitionContext.completeTransition(true)
                self.innerContext = nil
                self.lock.unlock()

                self.logger.debug("Finish end animation for ClipPreviewPageView dismissal")
            }
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = params.currentCornerRadius
        cornerAnimation.toValue = params.finalCornerRadius
        params.innerContext.animatingImageView.layer.cornerRadius = params.finalCornerRadius
        params.innerContext.animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.likepics_animate(
            withDuration: Self.endAnimateDuration,
            bounce: 0.2,
            delay: 0,
            options: [.curveEaseIn],
            animations: {
                switch params.dismissalType {
                case let .stickToThumbnail(thumbnailFrame: frame):
                    params.innerContext.animatingImageView.frame = frame

                case let .fadeout(cellFrame: frame):
                    params.innerContext.animatingImageView.frame = frame.scaled(0.2)
                    params.innerContext.animatingImageView.alpha = 0
                }

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
        lock.lock()
        defer { lock.unlock() }

        logger.debug("Start transition for ClipPreviewPageView dismissal")

        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresenting & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentable & UIViewController),
            let fromPreviewView = from.previewView(self),
            let fromImageView = fromPreviewView.imageView,
            let fromImage = fromImageView.image,
            let previewingClipItem = from.previewingClipItem(self),
            let toCell = to.animatingCell(self, id: previewingClipItem.cellIdentity, needsScroll: true),
            let toViewBaseView = to.baseView(self)
        else {
            logger.debug("Start fallback transition for ClipPreviewPageView dismissal")
            fallbackAnimator.startTransition(transitionContext, withDuration: Self.fallbackAnimateDuration, isInteractive: true)
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

        let initialImageFrame = from.clipPreviewAnimator(self, imageFrameOnContainerView: containerView)
        let animatingImageView = UIImageView(image: fromImage)
        animatingImageView.contentMode = .scaleAspectFill
        animatingImageView.clipsToBounds = true
        animatingImageView.frame = initialImageFrame
        animatingImageView.layer.cornerCurve = .continuous
        animatingImageView.layer.masksToBounds = true

        // Display Cell

        to.displayAnimatingCell(self, id: previewingClipItem.cellIdentity)

        // Preprocess

        from.view.backgroundColor = .clear
        toCell.alpha = 0
        fromImageView.isHidden = true

        toViewBaseView.addSubview(fromViewBackgroundView)
        toViewBaseView.insertSubview(animatingImageView, aboveSubview: fromViewBackgroundView)

        let postprocess = { (to: ClipPreviewPresentable, completion: @escaping () -> Void) in
            from.view.backgroundColor = fromViewBackgroundView.backgroundColor
            fromImageView.isHidden = false

            UIView.likepics_animate(
                withDuration: 0.15,
                animations: {
                    // CollectionViewの再描画により元のセルのインスタンスが破棄されている可能性があるため、
                    // 最新のセルのインスタンスを取得し直す
                    to.animatingCell(self, id: previewingClipItem.cellIdentity, needsScroll: true)?.alpha = 1
                },
                completion: { _ in
                    animatingImageView.alpha = 0
                    fromViewBackgroundView.removeFromSuperview()
                    animatingImageView.removeFromSuperview()
                    completion()
                }
            )
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
            let dismissalType: FinishAnimationParameters.DismissalType =
                previewingClipItem.isItemPrimary
                ? .stickToThumbnail(thumbnailFrame: to.thumbnailFrame(self, id: previewingClipItem.cellIdentity, needsScroll: false, on: containerView))
                : .fadeout(cellFrame: to.animatingCellFrame(self, id: previewingClipItem.cellIdentity, needsScroll: false, on: containerView))
            let params = FinishAnimationParameters(
                dismissalType: dismissalType,
                currentCornerRadius: 0,
                finalCornerRadius: to.animatingCellCornerRadius(self),
                from: from,
                to: to,
                innerContext: innerContext
            )
            lock.unlock()
            logger.debug("Immediately ended transition for ClipPreviewPageView dismissal")
            self.startEndAnimation(params: params)
            return
        }

        self.innerContext = innerContext
    }
}
