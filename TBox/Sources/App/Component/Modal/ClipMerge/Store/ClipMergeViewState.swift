//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct ClipMergeViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
    }

    var items: [ClipItem]
    var tags: [Tag]

    var alert: Alert?

    var isDismissed: Bool

    let sourceClipIds: Set<Clip.Identity>
}

extension ClipMergeViewState {
    init(clips: [Clip]) {
        self.items = clips.flatMap { $0.items }
        tags = []

        alert = nil

        isDismissed = false

        sourceClipIds = Set(clips.map { $0.id })
    }
}
