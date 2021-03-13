//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

protocol TextEditAlertDelegate: AnyObject {
    func textEditAlert(_ id: UUID, didTapSaveWithText: String)
    func textEditAlertDidCancel(_ id: UUID)
}
