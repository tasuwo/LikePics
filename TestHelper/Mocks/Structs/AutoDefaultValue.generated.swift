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
        thumbnail: ClipItem.Image = ClipItem.Image.makeDefault(),
        image: ClipItem.Image = ClipItem.Image.makeDefault(),
        registeredDate: Date = Date(timeIntervalSince1970: 0),
        updatedDate: Date = Date(timeIntervalSince1970: 0)
    ) -> Self {
        return .init(
            clipUrl: clipUrl,
            clipIndex: clipIndex,
            thumbnail: thumbnail,
            image: image,
            registeredDate: registeredDate,
            updatedDate: updatedDate
        )
    }
}

extension ClipItem.Image {
    static func makeDefault(
        url: URL = URL(string: "https://xxx.xxxx.xx")!,
        size: ImageSize = ImageSize.makeDefault()
    ) -> Self {
        return .init(
            url: url,
            size: size
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
