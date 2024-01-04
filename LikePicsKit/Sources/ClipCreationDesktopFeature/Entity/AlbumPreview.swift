//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct AlbumPreview: SuggestionItem {
    public var id: UUID
    public var title: String

    public init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}
