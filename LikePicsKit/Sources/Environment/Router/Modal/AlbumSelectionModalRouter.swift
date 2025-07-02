//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol AlbumSelectionModalRouter {
    @discardableResult
    func showAlbumSelectionModal(id: UUID) -> Bool
}

extension ModalNotification.Name {
    public static let albumSelectionModal = ModalNotification.Name("net.tasuwo.TBox.AlbumSelectionModalReducer.albumSelectionModal")
    public static let albumSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.AlbumSelectionModalReducer.albumSelectionModalDidDismiss")
}

extension ModalNotification.UserInfoKey {
    public static let selectedAlbumId = ModalNotification.UserInfoKey("net.tasuwo.TBox.AlbumSelectionModalReducer.selectedAlbumId")
}
