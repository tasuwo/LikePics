//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValuePublic
public struct ClipItemRecipe {
    public let id: UUID
    public let url: URL?
    public let clipId: Clip.Identity
    public let clipIndex: Int
    public let imageId: UUID
    public let imageFileName: String
    public let imageUrl: URL?
    public let imageSize: ImageSize
    public let imageDataSize: Int
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(id: UUID,
                url: URL?,
                clipId: Clip.Identity,
                clipIndex: Int,
                imageId: UUID,
                imageFileName: String,
                imageUrl: URL?,
                imageSize: ImageSize,
                imageDataSize: Int,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.id = id
        self.url = url
        self.clipId = clipId
        self.clipIndex = clipIndex
        self.imageId = imageId
        self.imageFileName = imageFileName
        self.imageUrl = imageUrl
        self.imageSize = imageSize
        self.imageDataSize = imageDataSize
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }

    public init(_ item: ClipItem) {
        self.id = item.id
        self.url = item.url
        self.clipId = item.clipId
        self.clipIndex = item.clipIndex
        self.imageId = item.imageId
        self.imageFileName = item.imageFileName
        self.imageUrl = item.imageUrl
        self.imageSize = item.imageSize
        self.imageDataSize = item.imageDataSize
        self.registeredDate = item.registeredDate
        self.updatedDate = item.updatedDate
    }
}
