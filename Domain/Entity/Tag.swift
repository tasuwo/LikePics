//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Tag: Equatable {
    public let id: String
    public let name: String

    // MARK: - Lifecycle

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

extension Tag: Identifiable {
    public typealias Identity = String

    public var identity: String {
        return self.id
    }
}

extension Tag: Hashable {}
