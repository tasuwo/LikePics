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
        case playConfig(id: UUID)
    }

    enum PageChange: String, Codable {
        case forward
        case reverse
    }

    let query: ClipPreviewPageQuery

    var clips: PreviewingClips
    var playConfiguration: ClipPreviewPlayConfiguration
    var playingAt: UUID?

    var currentIndexPath: ClipCollection.IndexPath
    var pageChange: PageChange?

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
    var isPageAnimated: Bool
}

extension ClipPreviewPageViewState {
    init(clips: [Clip],
         playConfiguration: ClipPreviewPlayConfiguration,
         query: ClipPreviewPageQuery,
         isSomeItemsHidden: Bool,
         indexPath: ClipCollection.IndexPath)
    {
        self.query = query
        self.currentIndexPath = indexPath
        self.clips = .init(clips: clips, isSomeItemsHidden: isSomeItemsHidden)
        self.playConfiguration = playConfiguration
        alert = nil
        isDismissed = false
        isPageAnimated = true
        playingAt = nil
    }
}

extension ClipPreviewPageViewState {
    var currentClip: Clip? {
        clips.clip(atIndex: currentIndexPath.clipIndex)
    }

    var currentItem: ClipItem? {
        clips.clipItem(atIndexPath: currentIndexPath)
    }

    func updated(by result: ClipPreviewIndexCoordinator.Result) -> Self {
        var newState = self
        newState.currentIndexPath = result.indexPath
        newState.pageChange = result.pageChange
        newState.isPageAnimated = result.isPageAnimated
        newState.isDismissed = result.isDismissed
        return newState
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
