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

extension SearchQuery {
    var queryNames: [String] {
        var queries = self.tokens.map { $0.title }

        if !text.isEmpty {
            queries.append(text)
        }

        return queries
    }

    var isEmpty: Bool { text.isEmpty && tokens.isEmpty }
}
