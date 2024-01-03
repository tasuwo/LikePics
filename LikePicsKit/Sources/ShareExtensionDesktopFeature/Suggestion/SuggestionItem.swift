//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

public protocol SuggestionItem: Identifiable, Hashable {
    var listingValue: String { get }
    var completionValue: String? { get }
}
