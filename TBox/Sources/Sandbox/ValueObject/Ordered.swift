//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct Ordered<Value: Equatable>: Equatable {
    let index: Int
    let value: Value
}
