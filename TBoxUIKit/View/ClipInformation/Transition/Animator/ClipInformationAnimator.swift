//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol ClipInformationAnimator {}

protocol ClipInformationPresentationAnimatorDelegate: AnyObject {
    func didFailToPresent(_ animator: ClipInformationAnimator)
}

protocol ClipInformationDismissalAnimatorDelegate: AnyObject {
    func didFailToDismiss(_ animator: ClipInformationAnimator)
}
