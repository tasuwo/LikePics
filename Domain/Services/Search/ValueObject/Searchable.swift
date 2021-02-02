//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol Searchable: Identifiable, Equatable {
    var searchableText: String? { get }
}

public extension String {
    func transformToSearchableText() -> String? {
        return self
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .lowercased()
    }
}
