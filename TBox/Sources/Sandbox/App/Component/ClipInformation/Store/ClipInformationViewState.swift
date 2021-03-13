//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipInformationViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case siteUrlEdit(title: String?)
    }

    let clipId: Clip.Identity
    let itemId: ClipItem.Identity

    var clip: Clip?
    var tags: Collection<Tag>
    var item: ClipItem?

    var isSomeItemsHidden: Bool
    var isHiddenStatusBar: Bool

    var alert: Alert?

    var isDismissed: Bool
}
