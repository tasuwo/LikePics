//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation
@testable import Persistence

extension ClipObject {
    static func makeDefault(id: String,
                            description: String = "hoge",
                            items: [ClipItemObject] = [],
                            tagIds: [TagIdObject] = [],
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
        tagIds.forEach {
            obj.tagIds.append($0)
        }
        obj.isHidden = isHidden
        obj.registeredAt = registeredAt
        obj.updatedAt = updatedAt
        return obj
    }
}

extension ClipItemObject {
    static func makeDefault(id: String = "",
                            url: URL? = nil,
                            clipId: String = "",
                            clipIndex: Int = 0,
                            imageId: String = "",
                            imageFileName: String = "",
                            imageUrl: URL? = nil,
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

extension TagIdObject {
    static func makeDefault(id: String) -> TagIdObject {
        let obj = TagIdObject()
        obj.id = id
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
