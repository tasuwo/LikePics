//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

@testable import Persistence

extension ClipObject {
    static func makeDefault(id: String,
                            description: String = "hoge",
                            items: [ClipItemObject] = [],
                            tags: [TagObject] = [],
                            isHidden: Bool = false,
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            updatedAt: Date = Date(timeIntervalSince1970: 1000)) -> ClipObject
    {
        let obj = ClipObject()
        obj.id = id
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
                            url: String? = nil,
                            clipId: String = "",
                            clipIndex: Int = 0,
                            imageId: String = "",
                            imageFileName: String = "",
                            imageUrl: String = "",
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            updatedAt: Date = Date(timeIntervalSince1970: 0)) -> ClipItemObject
    {
        let obj = ClipItemObject()
        obj.id = id
        obj.url = url
        obj.clipId = clipId
        obj.clipIndex = clipIndex
        obj.imageId = imageId
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

extension AlbumObject {
    static func makeDefault(id: String = "",
                            title: String = "",
                            clips: [ClipObject] = [],
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            updatedAt: Date = Date(timeIntervalSince1970: 0)) -> AlbumObject
    {
        let obj = AlbumObject()
        obj.id = id
        clips.forEach {
            obj.clips.append($0)
        }
        obj.title = title
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        return obj
    }
}

extension ReferenceClipObject {
    static func makeDefault(id: String = "",
                            descriptionText: String? = nil,
                            tags: [ReferenceTagObject] = [],
                            isHidden: Bool = false,
                            registeredAt: Date = Date(timeIntervalSince1970: 0),
                            isDirty: Bool = false) -> ReferenceClipObject
    {
        let obj = ReferenceClipObject()
        obj.id = id
        obj.descriptionText = descriptionText
        tags.forEach {
            obj.tags.append($0)
        }
        obj.isHidden = isHidden
        obj.registeredAt = registeredAt
        obj.isDirty = isDirty
        return obj
    }
}

extension ReferenceTagObject {
    static func makeDefault(id: String = "",
                            name: String = "",
                            isDirty: Bool = false) -> ReferenceTagObject
    {
        let obj = ReferenceTagObject()
        obj.id = id
        obj.name = name
        obj.isDirty = isDirty
        return obj
    }
}
