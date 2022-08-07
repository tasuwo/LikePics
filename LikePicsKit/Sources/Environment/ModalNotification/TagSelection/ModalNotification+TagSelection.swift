//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain

public extension ModalNotification.Name {
    static let tagSelectionModalDidSelect = ModalNotification.Name("net.tasuwo.TBox.TagSelectionModalReducer.tagSelectionModalDidSelect")
    static let tagSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.TagSelectionModalReducer.tagSelectionModalDidDismiss")
}

public extension ModalNotification.UserInfoKey {
    static let selectedTags = ModalNotification.UserInfoKey("net.tasuwo.TBox.TagSelectionModalReducer.selectedTags")
}
