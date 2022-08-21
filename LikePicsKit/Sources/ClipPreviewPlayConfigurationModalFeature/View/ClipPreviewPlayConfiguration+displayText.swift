//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipPreviewPlayConfiguration.Animation {
    var displayText: String {
        switch self {
        case .forward:
            return L10n.Any.ItemAnimationName.forward
        case .reverse:
            return L10n.Any.ItemAnimationName.reverse
        case .off:
            return L10n.Any.ItemAnimationName.off
        }
    }
}

extension ClipPreviewPlayConfiguration.Order {
    var displayText: String {
        switch self {
        case .forward:
            return L10n.Any.ItemOrderName.forward
        case .reverse:
            return L10n.Any.ItemOrderName.reverse
        case .random:
            return L10n.Any.ItemOrderName.random
        }
    }
}

extension ClipPreviewPlayConfiguration.Range {
    var displayText: String {
        switch self {
        case .overall:
            return L10n.Any.ItemRangeName.overall
        case .clip:
            return L10n.Any.ItemRangeName.clip
        }
    }
}
