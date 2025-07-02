//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol AlbumMultiSelectionModalRouter {
    @discardableResult
    func showAlbumMultiSelectionModal(id: UUID, selections: Set<Album.Identity>) -> Bool
}

extension ModalNotification.Name {
    public static let albumMultiSelectionModalDidSelect = ModalNotification.Name("net.tasuwo.TBox.AlbumMultiSelectionModalReducer.albumMultiSelectionModalDidSelect")
    public static let albumMultiSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.AlbumMultiSelectionModalReducer.albumMultiSelectionModalDidDismiss")
}

extension ModalNotification.UserInfoKey {
    public static let selectedAlbums = ModalNotification.UserInfoKey("net.tasuwo.TBox.AlbumMultiSelectionModalReducer.selectedAlbumIds")
}
