//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import WebKit

public protocol ClipCreationModalRouter {
    @discardableResult
    func showClipCreationModal(id: UUID, webView: WKWebView) -> Bool
}

extension ModalNotification.Name {
    public static let clipCreationModalDidFinish = ModalNotification.Name("net.tasuwo.TBox.ClipCreationViewReducer.ClipCreationModal")
}
