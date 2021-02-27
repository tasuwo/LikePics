//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipEditViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case siteUrlEdit(itemIds: Set<ClipItem.Identity>, title: String?)
    }

    struct EditingClip: Equatable {
        let id: Clip.Identity
        let dataSize: Int
        let isHidden: Bool
    }

    let clip: EditingClip
    let tags: Collection<Tag>
    let items: Collection<ClipItem>
    let isSomeItemsHidden: Bool

    let isItemsEditing: Bool

    let alert: Alert?

    let isDismissed: Bool
}

extension ClipEditViewState {
    var isItemDeletionEnabled: Bool { items.displayableValues.count > 1 }
}

extension ClipEditViewState {
    func updating(clip: EditingClip) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }

    func updating(tags: Collection<Tag>) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }

    func updating(items: Collection<ClipItem>) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }

    func updating(isSomeItemsHidden: Bool) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }

    func updating(isItemsEditing: Bool) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }

    func updating(alert: Alert?) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }

    func updating(isDismissed: Bool) -> Self {
        return .init(clip: clip,
                     tags: tags,
                     items: items,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isItemsEditing: isItemsEditing,
                     alert: alert,
                     isDismissed: isDismissed)
    }
}
