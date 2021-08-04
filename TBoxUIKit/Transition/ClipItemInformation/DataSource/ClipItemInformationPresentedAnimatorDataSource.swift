//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemInformationPresentedAnimatorDataSource {
    func animatingInformationView(_ animator: ClipItemInformationAnimator) -> ClipItemInformationView?
    func clipInformationAnimator(_ animator: ClipItemInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
}
