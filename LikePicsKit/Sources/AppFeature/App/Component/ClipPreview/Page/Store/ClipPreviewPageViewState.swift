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

    let query: ClipPreviewPageQuery

    var clips: PreviewingClips

    var currentIndexPath: ClipCollection.IndexPath
    var pageChange: PageChange?

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
    var isPageAnimated: Bool
}

extension ClipPreviewPageViewState {
    init(clips: [Clip],
         query: ClipPreviewPageQuery,
         isSomeItemsHidden: Bool,
         indexPath: ClipCollection.IndexPath)
    {
        self.query = query
        self.currentIndexPath = indexPath
        self.clips = .init(clips: clips, isSomeItemsHidden: isSomeItemsHidden)
        alert = nil
        isDismissed = false
        isPageAnimated = true
    }
}

extension ClipPreviewPageViewState {
    var currentClip: Clip? {
        clips.clip(atIndex: currentIndexPath.clipIndex)
    }

    var currentItem: ClipItem? {
        clips.clipItem(atIndexPath: currentIndexPath)
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
