//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct Album {
    public let id: String
    public let title: String
    public let clips: [Clip]
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(id: String, title: String, clips: [Clip], registeredDate: Date, updatedDate: Date) {
        self.id = id
        self.title = title
        self.clips = clips
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }

    // MARK: - Methods

    public func updatingClips(to clips: [Clip]) -> Self {
        return .init(id: self.id,
                     title: self.title,
                     clips: clips,
                     registeredDate: self.registeredDate,
                     updatedDate: self.updatedDate)
    }
}
