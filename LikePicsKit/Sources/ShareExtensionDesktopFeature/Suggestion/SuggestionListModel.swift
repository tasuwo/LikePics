//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

@Observable
class SuggestionListModel<Item: SuggestionItem> {
    var selectedId: Item.ID?
    var items: [Item]

    init(items: [Item]) {
        self.items = items
    }

    func moveSelectonUp() {
        guard let selectedId, let selectedIndex = items.firstIndex(where: { $0.id == selectedId }) else {
            selectedId = items.first?.id
            return
        }
        self.selectedId = items[max(0, selectedIndex - 1)].id
    }

    func moveSelectionDown() {
        guard let selectedId, let selectedIndex = items.firstIndex(where: { $0.id == selectedId }) else {
            selectedId = items.first?.id
            return
        }
        self.selectedId = items[min(items.count - 1, selectedIndex + 1)].id
    }
}
