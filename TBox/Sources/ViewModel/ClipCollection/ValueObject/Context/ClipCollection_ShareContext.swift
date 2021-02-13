//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum ShareSource {
        case menu(Clip.Identity)
        case toolBar
    }

    struct ShareContext {
        enum ActionSource: Equatable {
            case menu(Clip)
            case toolBar
        }

        let source: ActionSource
        let data: [Data]
    }
}
