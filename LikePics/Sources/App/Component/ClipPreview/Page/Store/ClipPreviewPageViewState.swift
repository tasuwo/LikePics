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
        guard clips.indices.contains(currentIndexPath.clipIndex),
              clips[currentIndexPath.clipIndex].items.indices.contains(currentIndexPath.itemIndex) else { return nil }
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
