//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

struct ClipCollectionState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case deletion(clipId: Clip.Identity)
        case purge(clipId: Clip.Identity)
        case share(clipId: Clip.Identity, items: [ClipItemImageShareItem])
    }

    let source: ClipCollection.Source
    var sourceDescription: String?

    var layout: ClipCollection.Layout
    var preservedLayout: ClipCollection.Layout?
    var operation: ClipCollection.Operation

    var clips: Collection<Clip>
    var previewingClipId: Clip.Identity?

    var isEmptyMessageViewDisplaying: Bool
    var isCollectionViewDisplaying: Bool

    var alert: Alert?

    var isDismissed: Bool

    var isSomeItemsHidden: Bool
}

extension ClipCollectionState {
    var isEditing: Bool {
        operation.isEditing
    }

    var isDragInteractionEnabled: Bool {
        source.isAlbum && !operation.isEditing
    }

    var isCollectionViewHidden: Bool {
        !isCollectionViewDisplaying
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewDisplaying ? 1 : 0
    }

    var previewingClip: Clip? {
        guard let clipId = previewingClipId else { return nil }
        return clips.value(having: clipId)
    }

    var title: String? {
        if operation != .selecting {
            if let description = sourceDescription {
                return "\(description) (\(clips._filteredIds.count))"
            } else {
                return nil
            }
        }
        return clips._selectedIds.isEmpty
            ? L10n.clipCollectionViewTitleSelect
            : L10n.clipCollectionViewTitleSelecting(clips._selectedIds.count)
    }
}
