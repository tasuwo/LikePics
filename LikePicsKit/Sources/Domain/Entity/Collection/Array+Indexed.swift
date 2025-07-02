//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension Array where Element: Identifiable & Codable & Equatable & Hashable {
    public func indexed() -> [Element.Identity: Ordered<Element>] {
        return self.enumerated().reduce(into: [Element.Identity: Ordered<Element>]()) { dict, keyValue in
            dict[keyValue.element.identity] = .init(index: keyValue.offset, value: keyValue.element)
        }
    }
}
