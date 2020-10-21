//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

@testable import Persistence

extension ClipObject {
    static func makeDefault(id: String,
                            url: String,
                            description: String = "hoge",
                            items: [ClipItemObject] = [],
                            tags: [TagObject] = [],
                            isHidden: Bool = false,
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            updatedAt: Date = Date(timeIntervalSince1970: 1000)) -> ClipObject
    {
        let obj = ClipObject()
        obj.id = id
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
    static func makeDefault(id: String = "",
                            clipId: String = "",
                            clipIndex: Int = 0,
                            imageFileName: String = "",
                            imageUrl: String = "",
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            updatedAt: Date = Date(timeIntervalSince1970: 0)) -> ClipItemObject
    {
        let obj = ClipItemObject()
        obj.id = id
        obj.clipId = clipId
        obj.clipIndex = clipIndex
        obj.imageFileName = imageFileName
        obj.imageUrl = imageUrl
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
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
