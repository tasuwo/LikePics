//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

class SuggestionListModel<Item: SuggestionItem>: ObservableObject {
    enum Selection: Hashable {
        case item(Item)
        case fallback

        var item: Item? {
            switch self {
            case let .item(item): item
            case .fallback: nil
            }
        }

        var isFallback: Bool {
            switch self {
            case .item: false
            case .fallback: true
            }
        }
    }

    @Published var items: [Item]
    @Published var fallbackItem: String?
    @Published var selection: Selection?

    var listSelection: SuggestionListSelection<Item>? {
        switch selection {
        case let .item(item):
            return .item(item)

        case .fallback:
            if let fallbackItem {
                return .fallback(fallbackItem)
            } else {
                return nil
            }

        case nil:
            return nil
        }
    }

    init(items: [Item]) {
        self.items = items
    }

    func moveSelectonUp() {
        switch selection {
        case let .item(selected):
            guard let selectedIndex = items.firstIndex(where: { $0.id == selected.id }) else {
                self.selection = headItemSelection()
                return
            }
            if selectedIndex - 1 < 0 {
                if fallbackItem != nil {
                    self.selection = .fallback
                }
            } else {
                self.selection = .item(items[selectedIndex - 1])
            }

        case .fallback:
            self.selection = headItemSelection()

        case nil:
            self.selection = headItemSelection()
        }
    }

    func moveSelectionDown() {
        switch selection {
        case let .item(selected):
            guard let selectedIndex = items.firstIndex(where: { $0.id == selected.id }) else {
                self.selection = headItemSelection()
                return
            }
            if selectedIndex + 1 < items.count {
                self.selection = .item(items[selectedIndex + 1])
            }

        case .fallback:
            if let firstItem = items.first {
                self.selection = .item(firstItem)
            }

        case nil:
            self.selection = headItemSelection()
        }
    }

    private func headItemSelection() -> Selection? {
        if fallbackItem != nil {
            .fallback
        } else if let firstItem = items.first {
            .item(firstItem)
        } else {
            nil
        }
    }
}
