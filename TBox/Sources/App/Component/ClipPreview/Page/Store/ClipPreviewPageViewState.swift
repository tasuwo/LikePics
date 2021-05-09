//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct ClipPreviewPageViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
    }

    enum PageChange {
        case forward
        case reverse
    }

    let clipId: Clip.Identity

    var currentIndex: Int?
    var pageChange: PageChange?
    var items: [ClipItem]

    var alert: Alert?

    var isDismissed: Bool
}

extension ClipPreviewPageViewState {
    init(clipId: Clip.Identity) {
        self.clipId = clipId
        currentIndex = nil
        items = []
        alert = nil
        isDismissed = false
    }
}

extension ClipPreviewPageViewState {
    var currentItem: ClipItem? {
        guard let index = currentIndex else { return nil }
        return items[index]
    }

    func index(of itemId: ClipItem.Identity) -> Int? {
        return items.firstIndex(where: { $0.id == itemId })
    }

    func item(after itemId: ClipItem.Identity) -> ClipItem? {
        guard let index = index(of: itemId), index + 1 < items.count else { return nil }
        return items[index + 1]
    }

    func item(before itemId: ClipItem.Identity) -> ClipItem? {
        guard let index = index(of: itemId), index - 1 >= 0 else { return nil }
        return items[index - 1]
    }

    func currentPreloadTargets() -> [UUID] {
        guard let index = currentIndex else { return [] }

        let preloadPages = 6

        let backwards = Set((index - preloadPages ... index - 1).clamped(to: 0 ... items.count - 1))
        let forwards = Set((index + 1 ... index + preloadPages).clamped(to: 0 ... items.count - 1))

        let preloadIndices = backwards.union(forwards).subtracting(Set([index]))

        return preloadIndices.map { items[$0].imageId }
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
