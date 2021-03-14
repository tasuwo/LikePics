//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct ClipCollectionState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case deletion(clipId: Clip.Identity)
        case purge(clipId: Clip.Identity)
        case share(clipId: Clip.Identity, data: [Data])
    }

    let source: ClipCollection.Source

    var title: String?
    var operation: ClipCollection.Operation

    var clips: Collection<Clip>
    var previewingClipId: Clip.Identity?

    var isEmptyMessageViewDisplaying: Bool
    var isCollectionViewDisplaying: Bool
    var isDragInteractionEnabled: Bool

    var alert: Alert?

    var isDismissed: Bool

    var isSomeItemsHidden: Bool
}

extension ClipCollectionState {
    var previewingClip: Clip? {
        guard let clipId = previewingClipId else { return nil }
        return clips._values[clipId]?.value
    }
}
