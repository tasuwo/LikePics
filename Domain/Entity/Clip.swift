//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct Clip {
    public let url: URL
    public let description: String?
    public let items: [ClipItem]

    // MARK: - Lifecycle

    public init(url: URL, description: String?, items: [ClipItem]) {
        self.url = url
        self.description = description
        self.items = items
    }
}
