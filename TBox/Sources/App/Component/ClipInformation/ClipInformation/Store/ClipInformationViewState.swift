//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipInformationViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case siteUrlEdit(title: String?)
    }

    enum Modal: Equatable {
        case tagSelection(tagIds: Set<Tag.Identity>)
    }

    let clipId: Clip.Identity
    let itemId: ClipItem.Identity

    var clip: Clip?
    var tags: EntityCollectionSnapshot<Tag>
    var item: ClipItem?

    var shouldCollectionViewUpdateWithAnimation: Bool
    var isSuspendedCollectionViewUpdate: Bool
    var isSomeItemsHidden: Bool
    var isHiddenStatusBar: Bool

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
}

extension ClipInformationViewState {
    init(clipId: Clip.Identity, itemId: ClipItem.Identity, isSomeItemsHidden: Bool) {
        self.clipId = clipId
        self.itemId = itemId
        clip = nil
        tags = .init()
        item = nil
        shouldCollectionViewUpdateWithAnimation = false
        isSuspendedCollectionViewUpdate = true
        self.isSomeItemsHidden = isSomeItemsHidden
        isHiddenStatusBar = false
        alert = nil
        isDismissed = false
    }
}
