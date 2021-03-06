//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class ClipPreviewNavigationController: UINavigationController {
    // MARK: - Properties

    override var prefersStatusBarHidden: Bool {
        return self.pageViewController?.prefersStatusBarHidden ?? true
    }

    private var pageViewController: ClipPreviewPageViewController? {
        viewControllers.first as? ClipPreviewPageViewController
    }

    // MARK: - Initializers

    init(pageViewController: ClipPreviewPageViewController) {
        super.init(rootViewController: pageViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setToolbarHidden(false, animated: false)

        view.backgroundColor = Asset.Color.background.color
    }
}

extension ClipPreviewNavigationController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    var previewingClipId: Clip.Identity? {
        pageViewController?.previewingClipId
    }

    func animatingPreviewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        return pageViewController?.animatingPreviewView(animator)
    }

    func isCurrentItemPrimary(_ animator: ClipPreviewAnimator) -> Bool {
        return pageViewController?.isCurrentItemPrimary(animator) == true
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        return pageViewController?.clipPreviewAnimator(animator, frameOnContainerView: containerView) ?? .zero
    }
}

extension ClipPreviewNavigationController: ClipInformationPresentingAnimatorDataSource {
    // MARK: - ClipInformationPresentingAnimatorDataSource

    func animatingPreviewView(_ animator: ClipInformationAnimator) -> ClipPreviewView? {
        return pageViewController?.animatingPreviewView(animator)
    }

    func baseView(_ animator: ClipInformationAnimator) -> UIView? {
        return pageViewController?.baseView(animator)
    }

    func componentsOverBaseView(_ animator: ClipInformationAnimator) -> [UIView] {
        return pageViewController?.componentsOverBaseView(animator) ?? []
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        return pageViewController?.clipInformationAnimator(animator, imageFrameOnContainerView: containerView) ?? .zero
    }

    func set(_ animator: ClipInformationAnimator, isUserInteractionEnabled: Bool) {
        pageViewController?.set(animator, isUserInteractionEnabled: isUserInteractionEnabled)
    }
}
