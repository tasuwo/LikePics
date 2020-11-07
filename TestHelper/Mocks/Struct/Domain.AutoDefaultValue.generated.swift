// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

@testable import Domain

extension Album {
    static func makeDefault(
        id: String = "",
        title: String = "",
        clips: [Clip] = [],
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            title: title,
            clips: clips,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension Clip {
    static func makeDefault(
        id: String = "",
        description: String? = nil,
        items: [ClipItem] = [],
        tags: [Tag] = [],
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            description: description,
            items: items,
            tags: tags,
            isHidden: isHidden,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension ClipItem {
    static func makeDefault(
        id: String = "",
        url: URL? = nil,
        clipId: String = "",
        clipIndex: Int = 0,
        imageFileName: String = "",
        imageUrl: URL? = nil,
        imageSize: ImageSize = ImageSize.makeDefault(),
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            url: url,
            clipId: clipId,
            clipIndex: clipIndex,
            imageFileName: imageFileName,
            imageUrl: imageUrl,
            imageSize: imageSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension ImageSize {
    static func makeDefault(
        height: Double = 0,
        width: Double = 0
    ) -> Self {
        return .init(
            height: height,
            width: width
        )
    }
}

extension ReferenceClip {
    static func makeDefault(
        id: String = "",
        description: String? = nil,
        tags: [ReferenceTag] = [],
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        isDirty: Bool = false
    ) -> Self {
        return .init(
            id: id,
            description: description,
            tags: tags,
            isHidden: isHidden,
            registeredDate: registeredDate,
            isDirty: isDirty
        )
    }
}

extension ReferenceTag {
    static func makeDefault(
        id: String = "",
        name: String = "",
        isDirty: Bool = false
    ) -> Self {
        return .init(
            id: id,
            name: name,
            isDirty: isDirty
        )
    }
}

extension Tag {
    static func makeDefault(
        id: String = "",
        name: String = ""
    ) -> Self {
        return .init(
            id: id,
            name: name
        )
    }
}
