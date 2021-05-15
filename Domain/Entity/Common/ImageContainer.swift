//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ImageContainer: Codable, Equatable, Hashable {
    public let id: Identity
    public let data: Data

    // MARK: - Lifecycle

    public init(id: Identity, data: Data) {
        self.id = id
        self.data = data
    }
}

extension ImageContainer: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}
