//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol AlbumSelectionModalRouter {
    @discardableResult
    func showAlbumSelectionModal(id: UUID) -> Bool
}

public extension ModalNotification.Name {
    static let albumSelectionModal = ModalNotification.Name("net.tasuwo.TBox.AlbumSelectionModalReducer.albumSelectionModal")
    static let albumSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.AlbumSelectionModalReducer.albumSelectionModalDidDismiss")
}

public extension ModalNotification.UserInfoKey {
    static let selectedAlbumId = ModalNotification.UserInfoKey("net.tasuwo.TBox.AlbumSelectionModalReducer.selectedAlbumId")
}
