//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct Clip {
    public let url: URL
    public let description: String?
    public let items: [ClipItem]
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(url: URL, description: String?, items: [ClipItem], registeredDate: Date, updatedDate: Date) {
        self.url = url
        self.description = description
        self.items = items
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }
}
