//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipPreviewPresentationAnimator: NSObject {
    static let transitionDuration: TimeInterval = 0.27

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
            let selectedImage = selectedImageView.image
        else {
            self.fallbackAnimator.startTransition(transitionContext, withDuration: Self.transitionDuration, isInteractive: false)
            return
        }

        targetImageView.isHidden = true
        selectedImageView.isHidden = true

        containerView.backgroundColor = .clear
        containerView.insertSubview(to.view, belowSubview: from.view)

        let animatingImageView = UIImageView(image: selectedImage)
        ClipsCollectionViewCell.setupAppearance(imageView: animatingImageView)
        animatingImageView.frame = from.clipPreviewAnimator(self, frameOnContainerView: containerView, forIndex: 0)
        containerView.addSubview(animatingImageView)

        to.view.alpha = 0

        CATransaction.begin()
        CATransaction.setAnimationDuration(self.transitionDuration(using: transitionContext))
        CATransaction.setCompletionBlock {
            targetImageView.isHidden = false
            selectedImageView.isHidden = false
            selectedCell.alpha = 1
            from.view.alpha = 1.0
            animatingImageView.removeFromSuperview()
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
            from.view.alpha = 0
            to.view.alpha = 1.0
        }

        CATransaction.commit()
    }

    func animationEnded(_ transitionCompleted: Bool) {
        self.delegate?.clipPreviewAnimator(self, didComplete: transitionCompleted)
    }
}
