//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol ClipMergeModalRouter {
    @discardableResult
    func showClipMergeModal(id: UUID, clips: [Clip]) -> Bool
}

extension ModalNotification.Name {
    public static let clipMergeModal = ModalNotification.Name("net.tasuwo.TBox.ClipMergeViewReducer.clipMergeModal")
}

extension ModalNotification.UserInfoKey {
    public static let clipMergeCompleted = ModalNotification.UserInfoKey("net.tasuwo.TBox.ClipMergeViewReducer.clipMergeCompleted")
}
