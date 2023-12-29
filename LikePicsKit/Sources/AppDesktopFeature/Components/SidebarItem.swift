//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import SwiftUI

enum SidebarItem: Hashable {
    case all
    case albums
    case album(Album.ID)
    case tag(Tag.ID)

    func tagId() -> Tag.ID? {
        guard case let .tag(selected) = self else { return nil }
        return selected
    }
}
