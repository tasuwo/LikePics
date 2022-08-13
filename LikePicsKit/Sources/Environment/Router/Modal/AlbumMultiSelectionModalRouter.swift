//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol AlbumMultiSelectionModalRouter {
    @discardableResult
    func showAlbumMultiSelectionModal(id: UUID, selections: Set<Album.Identity>) -> Bool
}

public extension ModalNotification.Name {
    static let albumMultiSelectionModalDidSelect = ModalNotification.Name("net.tasuwo.TBox.AlbumMultiSelectionModalReducer.albumMultiSelectionModalDidSelect")
    static let albumMultiSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.AlbumMultiSelectionModalReducer.albumMultiSelectionModalDidDismiss")
}

public extension ModalNotification.UserInfoKey {
    static let selectedAlbums = ModalNotification.UserInfoKey("net.tasuwo.TBox.AlbumMultiSelectionModalReducer.selectedAlbumIds")
}
