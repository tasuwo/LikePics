//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ClipSearchToken: Equatable, Hashable {
    public enum Kind {
        case tag
        case album
    }

    public let kind: Kind
    public let id: UUID
    public let title: String

    // MARK: - Initializers

    public init(kind: Kind, id: UUID, title: String) {
        self.kind = kind
        self.id = id
        self.title = title
    }
}
