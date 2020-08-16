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
}

extension ClipPreviewViewController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewPageView? {
        self.view.layoutIfNeeded()
        return self.pageViewController?.currentViewController?.pageView
    }

    func currentIndex(_ animator: ClipPreviewAnimator) -> Int? {
        self.view.layoutIfNeeded()
        return self.pageViewController?.currentIndex
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        self.view.layoutIfNeeded()
        guard let pageView = self.pageViewController?.currentViewController?.pageView else {
            return .zero
        }
        return pageView.convert(pageView.imageViewFrame, to: containerView)
    }
}
