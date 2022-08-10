//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

struct ClipItemInformationViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case siteUrlEdit(title: String?)
    }

    enum Modal: Equatable {
        case tagSelection(id: UUID, tagIds: Set<Tag.Identity>)
        case albumSelection(id: UUID)
    }

    let clipId: Clip.Identity
    let itemId: ClipItem.Identity

    var clip: Clip?
    var tags: EntityCollectionSnapshot<Tag>
    var item: ClipItem?
    var albums: EntityCollectionSnapshot<ListingAlbumTitle>

    var isSuspendedCollectionViewUpdate: Bool
    var isSomeItemsHidden: Bool
    var isHiddenStatusBar: Bool

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
}

extension ClipItemInformationViewState {
    init(clipId: Clip.Identity, itemId: ClipItem.Identity, isSomeItemsHidden: Bool) {
        self.clipId = clipId
        self.itemId = itemId
        clip = nil
        tags = .init()
        item = nil
        albums = .init()
        isSuspendedCollectionViewUpdate = true
        self.isSomeItemsHidden = isSomeItemsHidden
        isHiddenStatusBar = false
        alert = nil
        isDismissed = false
    }
}
