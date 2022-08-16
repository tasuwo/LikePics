// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

@testable import Domain

public extension Album {
    static func makeDefault(
        id: UUID = UUID(),
        title: String = "",
        clips: [Clip] = [],
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            title: title,
            clips: clips,
            isHidden: isHidden,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

public extension Clip {
    static func makeDefault(
        id: UUID = UUID(),
        description: String? = nil,
        items: [ClipItem] = [],
        isHidden: Bool = false,
        dataSize: Int = 0,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            description: description,
            items: items,
            isHidden: isHidden,
            dataSize: dataSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

public extension ClipItem {
    static func makeDefault(
        id: UUID = UUID(),
        url: URL? = nil,
        clipId: UUID = UUID(),
        clipIndex: Int = 0,
        imageId: UUID = UUID(),
        imageFileName: String = "",
        imageUrl: URL? = nil,
        imageSize: ImageSize = ImageSize.makeDefault(),
        imageDataSize: Int = 0,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            url: url,
            clipId: clipId,
            clipIndex: clipIndex,
            imageId: imageId,
            imageFileName: imageFileName,
            imageUrl: imageUrl,
            imageSize: imageSize,
            imageDataSize: imageDataSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

public extension ClipItemRecipe {
    static func makeDefault(
        id: UUID = UUID(),
        url: URL? = nil,
        clipId: UUID = UUID(),
        clipIndex: Int = 0,
        imageId: UUID = UUID(),
        imageFileName: String = "",
        imageUrl: URL? = nil,
        imageSize: ImageSize = ImageSize.makeDefault(),
        imageDataSize: Int = 0,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            url: url,
            clipId: clipId,
            clipIndex: clipIndex,
            imageId: imageId,
            imageFileName: imageFileName,
            imageUrl: imageUrl,
            imageSize: imageSize,
            imageDataSize: imageDataSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

public extension ClipRecipe {
    static func makeDefault(
        id: UUID = UUID(),
        description: String? = nil,
        items: [ClipItemRecipe] = [],
        tagIds: [UUID] = [],
        albumIds: Set<UUID> = [],
        isHidden: Bool = false,
        dataSize: Int = 0,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            description: description,
            items: items,
            tagIds: tagIds,
            albumIds: albumIds,
            isHidden: isHidden,
            dataSize: dataSize,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

public extension ImageSize {
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

public extension ListingAlbumTitle {
    static func makeDefault(
        id: UUID = UUID(),
        title: String = "",
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            id: id,
            title: title,
            isHidden: isHidden,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

public extension ReferenceAlbum {
    static func makeDefault(
        id: UUID = UUID(),
        title: String = "",
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0),
        isDirty: Bool = false
    ) -> Self {
        return .init(
            id: id,
            title: title,
            isHidden: isHidden,
            registeredDate: registeredDate,
            updatedDate: updatedDate,
            isDirty: isDirty
        )
    }
}

public extension ReferenceTag {
    static func makeDefault(
        id: UUID = UUID(),
        name: String = "",
        isHidden: Bool = false,
        clipCount: Int? = nil,
        isDirty: Bool = false
    ) -> Self {
        return .init(
            id: id,
            name: name,
            isHidden: isHidden,
            clipCount: clipCount,
            isDirty: isDirty
        )
    }
}

public extension Tag {
    static func makeDefault(
        id: UUID = UUID(),
        name: String = "",
        isHidden: Bool = false,
        clipCount: Int? = nil
    ) -> Self {
        return .init(
            id: id,
            name: name,
            isHidden: isHidden,
            clipCount: clipCount
        )
    }
}
