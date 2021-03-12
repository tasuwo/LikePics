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

    var pageViewController: NewClipPreviewPageViewController? {
        viewControllers.first as? NewClipPreviewPageViewController
    }

    // MARK: - Initializers

    init(pageViewController: NewClipPreviewPageViewController) {
        super.init(rootViewController: pageViewController)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Asset.Color.backgroundClient.color
    }
}

extension ClipPreviewNavigationController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return pageViewController?.currentViewController?.previewView
    }

    func currentItemId(_ animator: ClipPreviewAnimator) -> ClipItem.Identity? {
        view.layoutIfNeeded()
        return pageViewController?.currentItemId
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let pageView = pageViewController?.currentViewController?.previewView else { return .zero }
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }
}

extension ClipPreviewNavigationController: ClipInformationPresentingAnimatorDataSource {
    // MARK: - ClipInformationPresentingAnimatorDataSource

    func animatingPageView(_ animator: ClipInformationAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return pageViewController?.currentViewController?.previewView
    }

    func baseView(_ animator: ClipInformationAnimator) -> UIView? {
        return viewControllers.first?.view
    }

    func componentsOverBaseView(_ animator: ClipInformationAnimator) -> [UIView] {
        let toolBar = viewControllers.first?.navigationController?.toolbar
        return ([navigationBar, toolBar] as [UIView?]).compactMap { $0 }
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let pageView = self.pageViewController?.currentViewController?.previewView else { return .zero }
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }

    func set(_ animator: ClipInformationAnimator, isUserInteractionEnabled: Bool) {
        view.isUserInteractionEnabled = isUserInteractionEnabled
    }
}
