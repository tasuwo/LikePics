//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipMergeViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
    }

    let items: [ClipItem]
    let tags: [Tag]

    let alert: Alert?

    let sourceClipIds: Set<Clip.Identity>
    let isPresenting: Bool
}

extension ClipMergeViewState {
    func updating(items: [ClipItem]) -> Self {
        return .init(items: items,
                     tags: tags,
                     alert: alert,
                     sourceClipIds: sourceClipIds,
                     isPresenting: isPresenting)
    }

    func updating(tags: [Tag]) -> Self {
        return .init(items: items,
                     tags: tags,
                     alert: alert,
                     sourceClipIds: sourceClipIds,
                     isPresenting: isPresenting)
    }

    func updating(alert: Alert?) -> Self {
        return .init(items: items,
                     tags: tags,
                     alert: alert,
                     sourceClipIds: sourceClipIds,
                     isPresenting: isPresenting)
    }

    func updating(isPresenting: Bool) -> Self {
        return .init(items: items,
                     tags: tags,
                     alert: alert,
                     sourceClipIds: sourceClipIds,
                     isPresenting: isPresenting)
    }
}
