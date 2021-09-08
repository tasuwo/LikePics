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

    let source: ClipCollection.Source

    var currentIndexPath: ClipCollection.IndexPath
    var pageChange: PageChange?

    var clips: [Clip]
    var filteredClipIds: Set<Clip.Identity>

    var indexByClipId: [Clip.Identity: Int]
    var indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath]

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
    var isPageAnimated: Bool

    var isSomeItemsHidden: Bool
}

extension ClipPreviewPageViewState {
    init(clips: [Clip],
         source: ClipCollection.Source,
         isSomeItemsHidden: Bool,
         indexPath: ClipCollection.IndexPath)
    {
        self.clips = clips
        filteredClipIds = .init()
        self.source = source
        self.currentIndexPath = indexPath
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
        return clips[currentIndexPath.clipIndex]
    }

    var currentItem: ClipItem? {
        return clips[currentIndexPath.clipIndex].items[currentIndexPath.itemIndex]
    }

    func clip(of itemId: ClipItem.Identity) -> Clip? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }
        return clips[indexPath.clipIndex]
    }

    func indexPath(of itemId: ClipItem.Identity) -> ClipCollection.IndexPath? {
        return indexPathByClipItemId[itemId]
    }

    func item(after itemId: ClipItem.Identity) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }

        let clip = clips[indexPath.clipIndex]

        if indexPath.itemIndex + 1 < clip.items.count {
            return clip.items[indexPath.itemIndex + 1]
        } else if indexPath.clipIndex + 1 < clips.count {
            return clips[indexPath.clipIndex + 1].items.first
        } else {
            return nil
        }
    }

    func item(before itemId: ClipItem.Identity) -> ClipItem? {
        guard let indexPath = indexPathByClipItemId[itemId] else { return nil }

        let clip = clips[indexPath.clipIndex]

        if indexPath.itemIndex - 1 >= 0 {
            return clip.items[indexPath.itemIndex - 1]
        } else if indexPath.clipIndex - 1 >= 0 {
            return clips[indexPath.clipIndex - 1].items.last
        } else {
            return nil
        }
    }

    func currentPreloadTargets() -> [UUID] {
        // TODO:
        /*
         guard let index = currentIndex else { return [] }

         let preloadPages = 6

         let backwards = Set((index - preloadPages ... index - 1).clamped(to: 0 ... items.count - 1))
         let forwards = Set((index + 1 ... index + preloadPages).clamped(to: 0 ... items.count - 1))

         let preloadIndices = backwards.union(forwards).subtracting(Set([index]))

         return preloadIndices.map { items[$0].imageId }
          */
        return []
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
