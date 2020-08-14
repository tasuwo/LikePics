//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewViewController: UINavigationController {
    private var pageViewController: ClipPreviewPageViewController?

    // MARK: - Lifecycle

    init(pageViewController: ClipPreviewPageViewController) {
        self.pageViewController = pageViewController
        super.init(rootViewController: pageViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateToolbarAppearance()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.updateToolbarAppearance()
    }

    // MARK: - Methods

    private func updateToolbarAppearance() {
        self.setToolbarHidden(UIDevice.current.orientation.isLandscape, animated: false)
    }
}

extension ClipPreviewViewController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewPageView? {
        self.view.layoutIfNeeded()
        return self.pageViewController?.currentViewController?.pageView
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        self.view.layoutIfNeeded()
        guard let pageView = self.pageViewController?.currentViewController?.pageView else {
            return .zero
        }
        return pageView.convert(pageView.imageViewFrame, to: containerView)
    }
}
