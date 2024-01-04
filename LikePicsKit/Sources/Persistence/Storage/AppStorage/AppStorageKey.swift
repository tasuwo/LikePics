//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

public protocol AppStorageKey {
    associatedtype Value
    static var defaultValue: Self.Value { get }
    static var key: String { get }
}
