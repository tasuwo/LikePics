//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension Array where Element: Identifiable & Equatable & Hashable {
    func indexed() -> [Element.Identity: Ordered<Element>] {
        return self.enumerated().reduce(into: [Element.Identity: Ordered<Element>]()) { dict, keyValue in
            dict[keyValue.element.identity] = .init(index: keyValue.offset, value: keyValue.element)
        }
    }
}
