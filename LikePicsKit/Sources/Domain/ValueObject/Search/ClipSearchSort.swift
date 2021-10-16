//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchSort: Equatable, Hashable, Codable {
    public static let `default`: Self = .init(kind: .createdDate, order: .descent)

    public enum Order: String, Codable {
        case ascend
        case descent

        public var isAscending: Bool {
            return self == .ascend
        }
    }

    public enum Kind: String, Codable {
        case createdDate = "created_date"
        case updatedDate = "updated_date"
        case size = "size"
    }

    public let kind: Kind
    public let order: Order

    // MARK: - Initializers

    public init(kind: Kind, order: Order) {
        self.kind = kind
        self.order = order
    }
}
