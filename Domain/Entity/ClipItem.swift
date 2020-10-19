//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct ClipItem: Equatable {
    public let id: String
    public let clipId: String
    public let clipIndex: Int
    public let thumbnailFileName: String
    public let thumbnailUrl: URL?
    public let thumbnailSize: ImageSize
    public let imageFileName: String
    public let imageUrl: URL?
    public let imageSize: ImageSize
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(id: String,
                clipId: String,
                clipIndex: Int,
                thumbnailFileName: String,
                thumbnailUrl: URL?,
                thumbnailSize: ImageSize,
                imageFileName: String,
                imageUrl: URL?,
                imageSize: ImageSize,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.id = id
        self.clipId = clipId
        self.clipIndex = clipIndex
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailFileName = thumbnailFileName
        self.thumbnailSize = thumbnailSize
        self.imageFileName = imageFileName
        self.imageUrl = imageUrl
        self.imageSize = imageSize
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }
}

extension ClipItem: Identifiable {
    public typealias Identity = String

    public var identity: String {
        return self.id
    }
}

extension ClipItem: Hashable {}
