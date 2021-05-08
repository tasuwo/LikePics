//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationPresentingAnimatorDataSource {
    func animatingPreviewView(_ animator: ClipInformationAnimator) -> ClipPreviewView?
    func baseView(_ animator: ClipInformationAnimator) -> UIView?
    func componentsOverBaseView(_ animator: ClipInformationAnimator) -> [UIView]
    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
    func set(_ animator: ClipInformationAnimator, isUserInteractionEnabled: Bool)
}
