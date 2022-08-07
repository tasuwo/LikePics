//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

public protocol TagSelectionModalRouter {
    @discardableResult
    func showTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) -> Bool
}
