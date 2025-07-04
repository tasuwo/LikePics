//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipItemListDismissalAnimator: NSObject {
    static let transitionDuration: TimeInterval = 0.23

    private weak var delegate: AnimatorDelegate?
    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    // MARK: - Initializers

    init(delegate: AnimatorDelegate, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.delegate = delegate
        self.fallbackAnimator = fallbackAnimator
    }
}

extension ClipItemListDismissalAnimator: ClipItemListAnimator {}

extension ClipItemListDismissalAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipItemListPresenting & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipItemListPresentable & UIViewController),
            let previewingClipItem = to.previewingClipItem(self),
            let targetPreviewView = to.previewView(self),
            let selectedCell = from.animatingCell(self, id: previewingClipItem.cellIdentity)
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.transitionDuration, isInteractive: false)
            return
        }

        let selectedImageView = selectedCell.thumbnail()
        guard
            let selectedImage = selectedImageView.image
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.transitionDuration, isInteractive: false)
            return
        }

        /*
         アニメーション時、画像を Tab/Navigation Bar の裏側に回り込ませることで、自然なアニメーションを実現する
         このために、以下のような構成を取る
        
         ポイントは下記
        
         - アニメーション中 toView の背景色は clear にし、裏の View が見えるようにしておく
         - toView の背景色を徐々に表示するための ToViewBackgroundView を準備しておく
         - 最終的に toView に表示することになる画像Viewは ToViewBackgroundView の手前に配置する
         - Tab/Navigation Bar に画像が被らないように、画像Viewは Tab/NavigationBar の手前に配置する
         - アニメーション時は、以下を行う
             - ToViewBackgroundView を fadeIn
             - toView を fadeIn
             - Components over base views を fadeOut
        
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
          |    |    |    |    |    +--- ContainerView
          |    |    |    |    +-------- ToViewBackgroundView
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
          |             +-------------- FromView
          |
          +---------------------------- toView
         */

        // HACK: Set new frame for updating the view to current orientation.
        to.view.frame = from.view.frame

        targetPreviewView.viewWillStartTransition(
            frame: from.view.frame,
            thumbnail: selectedImage,
            originalImageSize: previewingClipItem.imageSize.cgSize
        )

        targetPreviewView.isHidden = true
        selectedImageView.isHidden = true

        let toViewBackgroundView = UIView()
        toViewBackgroundView.frame = to.view.frame
        toViewBackgroundView.backgroundColor = to.view.backgroundColor
        to.view.backgroundColor = .clear
        containerView.addSubview(toViewBackgroundView)

        let animatingImageView = UIImageView(image: selectedImage)
        animatingImageView.layer.cornerRadius = from.animatingCellCornerRadius(self)
        animatingImageView.contentMode = .scaleAspectFill
        animatingImageView.clipsToBounds = true
        animatingImageView.frame = from.thumbnailFrame(self, id: previewingClipItem.cellIdentity, on: containerView)
        containerView.insertSubview(animatingImageView, aboveSubview: toViewBackgroundView)

        containerView.insertSubview(to.view, aboveSubview: animatingImageView)

        to.view.alpha = 0
        toViewBackgroundView.alpha = 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            targetPreviewView.isHidden = false
            selectedImageView.isHidden = false
            selectedCell.alpha = 1
            from.componentsOverBaseView(self).forEach { $0.alpha = 1.0 }
            to.view.backgroundColor = toViewBackgroundView.backgroundColor

            // HACK: 性能が低い端末だとここの切り替え時に若干背景色がチラついてしまう問題があったため、一瞬削除を遅らせる
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                animatingImageView.removeFromSuperview()
                toViewBackgroundView.removeFromSuperview()
            }

            transitionContext.completeTransition(true)
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = from.animatingCellCornerRadius(self)
        cornerAnimation.toValue = 0
        animatingImageView.layer.cornerRadius = 0
        animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.likepics_animate(withDuration: 0.2) {
            selectedCell.alpha = 0
        }

        UIView.likepics_animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            animatingImageView.frame = to.clipItemListAnimator(self, imageFrameOnContainerView: containerView)

            to.view.alpha = 1.0
            toViewBackgroundView.alpha = 1.0
        }

        UIView.likepics_animate(
            withDuration: self.transitionDuration(using: transitionContext) / 3,
            delay: (self.transitionDuration(using: transitionContext) / 3) * 2,
            options: [.curveEaseIn]
        ) {
            from.componentsOverBaseView(self).forEach { $0.alpha = 0.0 }
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.animator(self, didComplete: transitionCompleted)
    }
}
