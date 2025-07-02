//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol ClipPreviewPlayConfigurationModalRouter {
    @discardableResult
    func showClipPreviewPlayConfigurationModal(id: UUID) -> Bool
}

extension ModalNotification.Name {
    public static let clipPreviewPlayConfigurationModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.ClipPreviewPlayConfigurationModal.didDismiss")
}
