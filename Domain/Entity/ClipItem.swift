//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ClipItem: Equatable {
    public let clipUrl: URL
    public let clipIndex: Int
    public let thumbnailFileName: String
    public let thumbnailUrl: URL?
    public let thumbnailSize: ImageSize
    public let imageFileName: String
    public let imageUrl: URL
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(clipUrl: URL,
                clipIndex: Int,
                thumbnailFileName: String,
                thumbnailUrl: URL?,
                thumbnailSize: ImageSize,
                imageFileName: String,
                imageUrl: URL,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.clipUrl = clipUrl
        self.clipIndex = clipIndex
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailFileName = thumbnailFileName
        self.thumbnailSize = thumbnailSize
        self.imageFileName = imageFileName
        self.imageUrl = imageUrl
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }
}
