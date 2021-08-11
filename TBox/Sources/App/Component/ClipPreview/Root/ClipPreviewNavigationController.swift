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

extension ClipPreviewNavigationController: TBoxUIKit.ClipPreviewViewController {
    // MARK: - ClipPreviewViewController

    func previewingClipItem(_ animator: ClipPreviewAnimator) -> PreviewingClipItem? {
        return pageViewController?.previewingClipItem(animator)
    }

    func animatingPreviewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        return pageViewController?.animatingPreviewView(animator)
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        return pageViewController?.clipPreviewAnimator(animator, frameOnContainerView: containerView) ?? .zero
    }
}

extension ClipPreviewNavigationController: ClipItemInformationPresentingAnimatorDataSource {
    // MARK: - ClipItemInformationPresentingAnimatorDataSource

    func animatingPreviewView(_ animator: ClipItemInformationAnimator) -> ClipPreviewView? {
        return pageViewController?.animatingPreviewView(animator)
    }

    func baseView(_ animator: ClipItemInformationAnimator) -> UIView? {
        return pageViewController?.baseView(animator)
    }

    func componentsOverBaseView(_ animator: ClipItemInformationAnimator) -> [UIView] {
        return pageViewController?.componentsOverBaseView(animator) ?? []
    }

    func clipItemInformationAnimator(_ animator: ClipItemInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        return pageViewController?.clipItemInformationAnimator(animator, imageFrameOnContainerView: containerView) ?? .zero
    }

    func set(_ animator: ClipItemInformationAnimator, isUserInteractionEnabled: Bool) {
        pageViewController?.set(animator, isUserInteractionEnabled: isUserInteractionEnabled)
    }
}
