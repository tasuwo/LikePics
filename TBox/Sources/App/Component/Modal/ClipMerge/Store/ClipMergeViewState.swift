//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct ClipMergeViewState: Equatable, KeyPathComparable {
    enum Alert: Equatable {
        case error(String?)
    }

    var items: [ClipItem]
    var tags: [Tag]

    var alert: Alert?

    var isDismissed: Bool

    let _sourceClipIds: Set<Clip.Identity>
}
