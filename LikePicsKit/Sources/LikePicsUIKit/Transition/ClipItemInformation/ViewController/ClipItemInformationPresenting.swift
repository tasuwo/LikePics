//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemInformationPresenting {
    func clipItem(_ animator: ClipItemInformationAnimator) -> InfoViewingClipItem?
    func clipInformationView(_ animator: ClipItemInformationAnimator) -> ClipItemInformationView?
    func clipInformationAnimator(_ animator: ClipItemInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
}
