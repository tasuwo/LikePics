// Generated using Sourcery 1.0.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

@testable import Domain
@testable import Persistence
@testable import TBoxUIKit

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
        url: URL = URL(string: "https://xxx.xxxx.xx")!,
        description: String? = nil,
        items: [ClipItem] = [],
        tags: [String] = [],
        isHidden: Bool = false,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            url: url,
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
        clipUrl: URL = URL(string: "https://xxx.xxxx.xx")!,
        clipIndex: Int = 0,
        thumbnailFileName: String = "",
        thumbnailUrl: URL? = nil,
        thumbnailSize: ImageSize = ImageSize.makeDefault(),
        imageFileName: String = "",
        imageUrl: URL = URL(string: "https://xxx.xxxx.xx")!,
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            clipUrl: clipUrl,
            clipIndex: clipIndex,
            thumbnailFileName: thumbnailFileName,
            thumbnailUrl: thumbnailUrl,
            thumbnailSize: thumbnailSize,
            imageFileName: imageFileName,
            imageUrl: imageUrl,
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
