//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import MobileTransition

public protocol ClipItemListModalRouter {
    @discardableResult
    func showClipItemListModal(id: UUID,
                               clipId: Clip.Identity,
                               clipItems: [ClipItem],
                               transitioningController: ClipItemListTransitioningControllable) -> Bool
}

public extension ModalNotification.Name {
    static let clipItemList = ModalNotification.Name("net.tasuwo.TBox.ClipItemListReducer.clipItemList")
}

public extension ModalNotification.UserInfoKey {
    static let selectedPreviewItem = ModalNotification.UserInfoKey("net.tasuwo.TBox.ClipItemListReducer.selectedPreviewItem")
}
