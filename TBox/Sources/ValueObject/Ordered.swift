//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct Ordered<Value: Equatable & Hashable>: Equatable, Hashable {
    let index: Int
    let value: Value
}
