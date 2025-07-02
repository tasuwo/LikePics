//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import SwiftUI

@MainActor
final class DragAndDropInteractionController<Store: ReorderableItemStore>: ObservableObject {
    typealias Item = Store.Item

    @Published private(set) var displayItems: [Item]
    @Published private(set) var isDraggingOnItem: Bool = false

    private var draggingItemId: Item.ID?
    private let underlyingStore: Store
    private var dropExitTask: Task<Void, Never>? {
        willSet {
            dropExitTask?.cancel()
        }
    }

    private var cancellable: AnyCancellable? = nil

    init(underlying underlyingStore: Store) {
        self.displayItems = underlyingStore.reorderableItems
        self.underlyingStore = underlyingStore

        cancellable = underlyingStore.reorderableItemsPublisher
            .sink { [weak self] items in
                guard let self, !self.isDraggingOnItem else { return }
                self.displayItems = items
            }
    }

    func onDragStart(forItemHaving id: Item.ID) {
        draggingItemId = id
    }

    func onPerformDrop(forItemHaving id: Item.ID) -> Bool {
        isDraggingOnItem = false
        underlyingStore.apply(reorderedItems: displayItems)
        draggingItemId = nil
        return true
    }

    func onDragEnter(toItemHaving id: Item.ID) {
        dropExitTask = nil

        guard let draggingItemId,
            let fromIndex = displayItems.firstIndex(where: { $0.id == draggingItemId }),
            let toIndex = displayItems.firstIndex(where: { $0.id == id })
        else {
            clearArranging()
            draggingItemId = nil
            return
        }

        isDraggingOnItem = true
        withAnimation {
            let removed = displayItems.remove(at: fromIndex)
            displayItems.insert(removed, at: toIndex)
        }
    }

    func onDragExit(fromItemHaving id: Item.ID) {
        dropExitTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation {
                self?.clearArranging()
            }
        }
    }

    func isValidDrop(forItemHaving id: Item.ID) -> Bool {
        return draggingItemId != nil
    }

    private func clearArranging() {
        isDraggingOnItem = false
        displayItems = underlyingStore.reorderableItems
    }
}
