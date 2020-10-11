//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

@testable import Persistence

extension ClipObject {
    static func makeDefault(url: String,
                            description: String = "hoge",
                            items: [ClipItemObject] = [],
                            tags: [TagObject] = [],
                            isHidden: Bool = false,
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            updatedAt: Date = Date(timeIntervalSince1970: 1000)) -> ClipObject
    {
        let obj = ClipObject()
        obj.url = url
        obj.descriptionText = description
        items.forEach {
            obj.items.append($0)
        }
        tags.forEach {
            obj.tags.append($0)
        }
        obj.isHidden = isHidden
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        return obj
    }
}

extension ClipItemObject {
    static func makeDefault(clipUrl: String,
                            clipIndex: Int,
                            thumbnailFileName: String,
                            thumbnailHeight: Double,
                            thumbnailWidth: Double,
                            imageFileName: String,
                            imageUrl: String,
                            registeredAt: Date,
                            updatedAt: Date) -> ClipItemObject
    {
        let obj = ClipItemObject()
        obj.clipUrl = clipUrl
        obj.clipIndex = clipIndex
        obj.thumbnailFileName = thumbnailFileName
        obj.thumbnailHeight = thumbnailHeight
        obj.thumbnailWidth = thumbnailWidth
        obj.imageFileName = imageFileName
        obj.imageUrl = imageUrl
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        obj.key = obj.makeKey()
        return obj
    }
}

extension TagObject {
    static func makeDefault(id: String, name: String) -> TagObject {
        let obj = TagObject()
        obj.id = id
        obj.name = name
        return obj
    }
}
