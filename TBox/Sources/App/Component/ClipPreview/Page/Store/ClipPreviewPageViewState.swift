//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct ClipPreviewPageViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
    }

    enum Modal: Equatable {
        case clipItemList(id: UUID)
        case albumSelection(id: UUID)
        case tagSelection(id: UUID, tagIds: Set<Tag.Identity>)
    }

    enum PageChange: String, Codable {
        case forward
        case reverse
    }

    enum Query: Equatable {
        case clips(ClipCollection.Source)
        case searchResult(ClipSearchQuery)
    }

    let query: Query

    var currentIndexPath: ClipCollection.IndexPath
    var filteredClipIds: Set<Clip.Identity>
    var clips: [Clip]

    var pageChange: PageChange?

    var indexByClipId: [Clip.Identity: Int]
    var indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath]

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
    var isPageAnimated: Bool

    var isSomeItemsHidden: Bool
}

extension ClipPreviewPageViewState {
    init(filteredClipIds: Set<Clip.Identity>,
         clips: [Clip],
         query: Query,
         isSomeItemsHidden: Bool,
         indexPath: ClipCollection.IndexPath)
    {
        self.query = query
        self.currentIndexPath = indexPath
        self.filteredClipIds = filteredClipIds
        self.clips = clips
        self.isSomeItemsHidden = isSomeItemsHidden
        indexByClipId = [:]
        indexPathByClipItemId = [:]
        alert = nil
        isDismissed = false
        isPageAnimated = true
    }
}

extension ClipPreviewPageViewState {
    var currentClip: Clip? {
        guard clips.indices.contains(currentIndexPath.clipIndex) else { return nil }
        return clips[currentIndexPath.clipIndex]
    }

    var currentItem: ClipItem? {
        guard clips.indices.contains(currentIndexPath.clipIndex) else { return nil }
        return clips[currentIndexPath.clipIndex].items[currentIndexPath.itemIndex]
    }

    func clip(of itemId: ClipItem.Identity) -> Clip? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard clips.indices.contains(indexPath.clipIndex) else { return nil }
        return clips[indexPath.clipIndex]
    }

    func indexPath(of itemId: ClipItem.Identity) -> ClipCollection.IndexPath? {
        return indexPathByClipItemId[itemId]
    }

    func item(after itemId: ClipItem.Identity) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard clips.indices.contains(indexPath.clipIndex) else { return nil }

        let currentClip = clips[indexPath.clipIndex]

        if indexPath.itemIndex + 1 < currentClip.items.count {
            return currentClip.items[indexPath.itemIndex + 1]
        } else {
            guard indexPath.clipIndex + 1 < clips.count else { return nil }
            for clipIndex in indexPath.clipIndex + 1 ... clips.count - 1 {
                if filteredClipIds.contains(clips[clipIndex].id) {
                    return clips[clipIndex].items.first
                }
            }
            return nil
        }
    }

    func item(before itemId: ClipItem.Identity) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        guard clips.indices.contains(indexPath.clipIndex) else { return nil }

        let currentClip = clips[indexPath.clipIndex]

        if indexPath.itemIndex - 1 >= 0 {
            return currentClip.items[indexPath.itemIndex - 1]
        } else {
            guard indexPath.clipIndex - 1 >= 0 else { return nil }
            for clipIndex in (0 ... indexPath.clipIndex - 1).reversed() {
                if filteredClipIds.contains(clips[clipIndex].id) {
                    return clips[clipIndex].items.last
                }
            }
            return nil
        }
    }

    func currentPreloadTargets() -> [UUID] {
        guard let currentItem = currentItem else { return [] }

        var forwards: [UUID] = []
        var backwards: [UUID] = []

        var baseItem = currentItem
        for _ in 0 ..< 6 {
            guard let nextItem = item(after: baseItem.id) else { break }
            forwards.append(nextItem.imageId)
            baseItem = nextItem
        }

        baseItem = currentItem
        for _ in 0 ..< 6 {
            guard let previousItem = item(before: baseItem.id) else { break }
            backwards.append(previousItem.imageId)
            baseItem = previousItem
        }

        return forwards + backwards
    }
}

extension ClipPreviewPageViewState.PageChange {
    var navigationDirection: UIPageViewController.NavigationDirection {
        switch self {
        case .forward:
            return .forward

        case .reverse:
            return .reverse
        }
    }
}

// MARK: - Codable

extension ClipPreviewPageViewState: Codable {}

extension ClipPreviewPageViewState.Alert: Codable {
    enum CodingKeys: CodingKey {
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .error:
            let message = try container.decodeIfPresent(String.self, forKey: .error)
            self = .error(message)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .error(message):
            try container.encode(message, forKey: .error)
        }
    }
}

extension ClipPreviewPageViewState.Modal: Codable {
    enum CodingKeys: CodingKey {
        case albumSelection
        case clipItemList
        case tagSelection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .albumSelection:
            let id = try container.decode(UUID.self, forKey: .albumSelection)
            self = .albumSelection(id: id)

        case .clipItemList:
            let id = try container.decode(UUID.self, forKey: .clipItemList)
            self = .clipItemList(id: id)

        case .tagSelection:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .tagSelection)
            let id = try nestedContainer.decode(UUID.self)
            let tagIds = try nestedContainer.decode(Set<Tag.Identity>.self)
            self = .tagSelection(id: id, tagIds: tagIds)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .albumSelection(id: id):
            try container.encode(id, forKey: .albumSelection)

        case let .clipItemList(id: id):
            try container.encode(id, forKey: .clipItemList)

        case let .tagSelection(id: id, tagIds: tagIds):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .tagSelection)
            try nestedContainer.encode(id)
            try nestedContainer.encode(tagIds)
        }
    }
}

extension ClipPreviewPageViewState.Query: Codable {
    enum CodingKeys: CodingKey {
        case query
        case searchResult
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .query:
            let source = try container.decode(ClipCollection.Source.self, forKey: .query)
            self = .clips(source)

        case .searchResult:
            let query = try container.decode(ClipSearchQuery.self, forKey: .searchResult)
            self = .searchResult(query)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .clips(source):
            try container.encode(source, forKey: .query)

        case let .searchResult(query):
            try container.encode(query, forKey: .searchResult)
        }
    }
}
