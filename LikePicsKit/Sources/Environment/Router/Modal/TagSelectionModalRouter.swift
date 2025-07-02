//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol TagSelectionModalRouter {
    @discardableResult
    func showTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) -> Bool
}

extension ModalNotification.Name {
    public static let tagSelectionModalDidSelect = ModalNotification.Name("net.tasuwo.TBox.TagSelectionModalReducer.tagSelectionModalDidSelect")
    public static let tagSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.TagSelectionModalReducer.tagSelectionModalDidDismiss")
}

extension ModalNotification.UserInfoKey {
    public static let selectedTags = ModalNotification.UserInfoKey("net.tasuwo.TBox.TagSelectionModalReducer.selectedTags")
}
