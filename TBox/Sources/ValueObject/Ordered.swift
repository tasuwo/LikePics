//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct Ordered<Value: Codable & Hashable>: Codable, Hashable {
    let index: Int
    let value: Value
}
