//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

struct ClipMergeViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
    }

    enum Modal: Equatable {
        case tagSelection(id: UUID, tagIds: Set<Tag.Identity>)
    }

    let id: UUID

    var items: [ClipItem]
    var tags: [Tag]

    var alert: Alert?
    var modal: Modal?
    var overwriteSiteUrl: URL?
    var shouldSaveAsHiddenItem: Bool

    var isDismissed: Bool

    let sourceClipIds: Set<Clip.Identity>
}

extension ClipMergeViewState {
    init(id: UUID, clips: [Clip]) {
        self.id = id
        self.items = clips.flatMap { $0.items }
        tags = []

        alert = nil

        overwriteSiteUrl = nil
        shouldSaveAsHiddenItem = clips.contains(where: { $0.isHidden })

        isDismissed = false

        sourceClipIds = Set(clips.map { $0.id })
    }
}
