//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemInformationPresentable {
    func previewView(_ animator: ClipItemInformationAnimator) -> ClipPreviewView?
    func baseView(_ animator: ClipItemInformationAnimator) -> UIView?
    func componentsOverBaseView(_ animator: ClipItemInformationAnimator) -> [UIView]
    func clipItemInformationAnimator(_ animator: ClipItemInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
    func set(_ animator: ClipItemInformationAnimator, isUserInteractionEnabled: Bool)
}
