//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct LightweightClip: Equatable {
    public let id: String
    public let url: URL?
    public let tags: [LightweightTag]

    // MARK: - Lifecycle

    public init(id: String,
                url: URL?,
                tags: [LightweightTag])
    {
        self.id = id
        self.url = url
        self.tags = tags
    }
}

extension LightweightClip: Identifiable {
    public typealias Identity = Clip.Identity

    public var identity: Clip.Identity {
        return self.id
    }
}

extension LightweightClip: Hashable {}
