//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import Foundation

class SuggestionListModel<Item: SuggestionItem>: ObservableObject {
    enum Selection: Hashable {
        case item(Item.ID)
        case fallback

        var itemId: Item.ID? {
            switch self {
            case let .item(id): id
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

    @Published var items: [Item] {
        didSet {
            self.itemIndicesById = Self.composeDictionary(by: items)
        }
    }

    @Published var fallbackItem: String?
    @Published var selection: Selection?

    var listSelection: SuggestionListSelection<Item>? {
        switch selection {
        case let .item(id):
            return .item(id)

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

    private(set) var itemIndicesById: [Item.ID: Int]

    init(items: [Item]) {
        self.items = items
        self.itemIndicesById = Self.composeDictionary(by: items)
    }

    func item(having itemId: Item.ID) -> Item? {
        guard let index = itemIndicesById[itemId], items.indices.contains(index) else {
            return nil
        }
        return items[index]
    }

    func moveSelectonUp() {
        switch selection {
        case let .item(selectedId):
            guard let selectedIndex = items.firstIndex(where: { $0.id == selectedId }) else {
                self.selection = headItemSelection()
                return
            }
            if selectedIndex - 1 < 0 {
                if let fallbackItem {
                    self.selection = .fallback
                }
            } else {
                self.selection = .item(items[selectedIndex - 1].id)
            }

        case .fallback:
            self.selection = headItemSelection()

        case nil:
            self.selection = headItemSelection()
        }
    }

    func moveSelectionDown() {
        switch selection {
        case let .item(selectedId):
            guard let selectedIndex = items.firstIndex(where: { $0.id == selectedId }) else {
                self.selection = headItemSelection()
                return
            }
            if selectedIndex + 1 < items.count {
                self.selection = .item(items[selectedIndex + 1].id)
            }

        case .fallback:
            if let firstItemId = items.first?.id {
                self.selection = .item(firstItemId)
            }

        case nil:
            self.selection = headItemSelection()
        }
    }

    private func headItemSelection() -> Selection? {
        if let fallbackItem {
            .fallback
        } else if let firstItemId = items.first?.id {
            .item(firstItemId)
        } else {
            nil
        }
    }

    private static func composeDictionary(by items: [Item]) -> [Item.ID: Int] {
        var index = 0
        var itemIndicesById = [Item.ID: Int]()
        for item in items {
            itemIndicesById[item.id] = index
            index += 1
        }
        return itemIndicesById
    }
}
