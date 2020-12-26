//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationPresentingAnimatorDataSource {
    func animatingPageView(_ animator: ClipInformationAnimator) -> ClipPreviewView?
    func presentingView(_ animator: ClipInformationAnimator) -> UIView?
    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
}