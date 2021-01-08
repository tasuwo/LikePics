//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    struct ShareContext {
        enum ActionSource: Equatable {
            case menu(Clip)
            case toolBar
        }

        let source: ActionSource
        let data: [Data]
    }
}
