//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol ReorderableItemStore: ObservableObject {
    associatedtype Item: Identifiable
    var reorderableItemsPublisher: AnyPublisher<[Item], Never> { get }
    var reorderableItems: [Item] { get }
    func apply(reorderedItems: [Item])
}
