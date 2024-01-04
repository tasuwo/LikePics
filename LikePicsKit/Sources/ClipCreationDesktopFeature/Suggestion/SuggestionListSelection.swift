//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

public enum SuggestionListSelection<Item: SuggestionItem>: Hashable {
    case item(Item)
    case fallback(String)
}
