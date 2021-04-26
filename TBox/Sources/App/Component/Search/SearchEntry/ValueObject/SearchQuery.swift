//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct SearchQuery: Equatable {
    let tokens: [SearchToken]
    let text: String

    func appending(token: SearchToken) -> Self {
        return .init(tokens: tokens + [token], text: text)
    }
}
