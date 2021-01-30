//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewPresentationAnimator: NSObject {
    static let transitionDuration: TimeInterval = 0.23

    private weak var delegate: ClipPreviewAnimatorDelegate?
    private let fallbackAnimator: FadeTransitionAnimatorProtocol

    // MARK: - Lifecycle

    init(delegate: ClipPreviewAnimatorDelegate, fallbackAnimator: FadeTransitionAnimatorProtocol) {
        self.delegate = delegate
        self.fallbackAnimator = fallbackAnimator
    }
}

extension ClipPreviewPresentationAnimator: ClipPreviewAnimator {}

extension ClipPreviewPresentationAnimator: UIViewControllerAnimatedTransitioning {
    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        guard
            let from = transitionContext.viewController(forKey: .from) as? (ClipPreviewPresentingAnimatorDataSource & UIViewController),
            let to = transitionContext.viewController(forKey: .to) as? (ClipPreviewPresentedAnimatorDataSource & UIViewController),
            let targetImageView = to.animatingPage(self),
            let selectedCell = from.animatingCell(self),
            let selectedImageView = selectedCell.primaryImageView,
            let selectedImage = selectedImageView.image,
            let fromViewBaseView = from.baseView(self)
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
          |    |    |    |    |    +--- FromViewBaseView
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

        targetImageView.isHidden = true
        selectedImageView.isHidden = true

        containerView.insertSubview(to.view, aboveSubview: from.view)

        let toViewBackgroundView = UIView()
        toViewBackgroundView.frame = fromViewBaseView.frame
        toViewBackgroundView.backgroundColor = to.view.backgroundColor
        to.view.backgroundColor = .clear
        fromViewBaseView.addSubview(toViewBackgroundView)

        let animatingImageView = UIImageView(image: selectedImage)
        ClipCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = from.clipPreviewAnimator(self, frameOnContainerView: containerView, forItemId: nil)
        fromViewBaseView.insertSubview(animatingImageView, aboveSubview: toViewBackgroundView)

        to.view.alpha = 0
        toViewBackgroundView.alpha = 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            targetImageView.isHidden = false
            selectedImageView.isHidden = false
            selectedCell.alpha = 1
            from.componentsOverBaseView(self).forEach { $0.alpha = 1.0 }
            to.view.backgroundColor = toViewBackgroundView.backgroundColor
            animatingImageView.removeFromSuperview()
            toViewBackgroundView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        let cornerAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.cornerRadius))
        cornerAnimation.fromValue = 10
        cornerAnimation.toValue = 0
        animatingImageView.layer.cornerRadius = 0
        animatingImageView.layer.add(cornerAnimation, forKey: #keyPath(CALayer.cornerRadius))

        UIView.animate(withDuration: 0.2) {
            selectedCell.alpha = 0
        }

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            animatingImageView.frame = to.clipPreviewAnimator(self, frameOnContainerView: containerView)

            to.view.alpha = 1.0
            toViewBackgroundView.alpha = 1.0
        }

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext) / 3,
            delay: (self.transitionDuration(using: transitionContext) / 3) * 2,
            options: [.curveEaseIn]
        ) {
            from.componentsOverBaseView(self).forEach { $0.alpha = 0.0 }
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.clipPreviewAnimator(self, didComplete: transitionCompleted)
    }
}
