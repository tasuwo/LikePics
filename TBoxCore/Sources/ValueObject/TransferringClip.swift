//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct TransferringClip {
    public struct Tag {
        public let id: String
        public let name: String

        // MARK: - Lifecycle

        public init(id: String, name: String) {
            self.id = id
            self.name = name
        }
    }

    public let id: String
    public let description: String?
    public let tags: [Tag]
    public let isHidden: Bool
    public let registeredDate: Date

    // MARK: - Lifecycle

    public init(id: String,
                description: String?,
                tags: [Tag],
                isHidden: Bool,
                registeredDate: Date)
    {
        self.id = id
        self.description = description
        self.tags = tags
        self.isHidden = isHidden
        self.registeredDate = registeredDate
    }
}
