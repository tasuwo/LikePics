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

extension ClipPreviewNavigationController: ClipPreviewPresenting {
    // MARK: - ClipPreviewPresenting

    func previewingClipItem(_ animator: ClipPreviewAnimator) -> PreviewingClipItem? {
        return pageViewController?.previewingClipItem(animator)
    }

    func previewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        return pageViewController?.previewView(animator)
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        return pageViewController?.clipPreviewAnimator(animator, imageFrameOnContainerView: containerView) ?? .zero
    }
}

extension ClipPreviewNavigationController: ClipItemListPresentable {
    // MARK: - ClipItemListPresentable

    func previewingClipItem(_ animator: ClipItemListAnimator) -> PreviewingClipItem? {
        return pageViewController?.previewingClipItem(animator)
    }

    func previewView(_ animator: ClipItemListAnimator) -> ClipPreviewView? {
        return pageViewController?.previewView(animator)
    }

    func clipItemListAnimator(_ animator: ClipItemListAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        return pageViewController?.clipItemListAnimator(animator, imageFrameOnContainerView: containerView) ?? .zero
    }
}

extension ClipPreviewNavigationController: ClipItemInformationPresentable {
    // MARK: - ClipItemInformationPresentable

    func previewView(_ animator: ClipItemInformationAnimator) -> ClipPreviewView? {
        return pageViewController?.previewView(animator)
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
