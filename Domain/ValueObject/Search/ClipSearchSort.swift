//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchSort: Equatable, Hashable, Codable {
    public enum Order: String, Codable {
        case ascend
        case descent

        public var isAscending: Bool {
            return self == .ascend
        }
    }

    public enum Kind: String, Codable {
        case createdDate
        case updatedDate
        case size
    }

    public let kind: Kind
    public let order: Order

    // MARK: - Initializers

    public init(kind: Kind, order: Order) {
        self.kind = kind
        self.order = order
    }
}
