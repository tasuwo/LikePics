//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipPreviewPageViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
    }

    let clipId: Clip.Identity

    var isFullscreen: Bool

    var currentIndex: Int?
    var items: [ClipItem]

    var alert: Alert?

    var isDismissed: Bool
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
}
