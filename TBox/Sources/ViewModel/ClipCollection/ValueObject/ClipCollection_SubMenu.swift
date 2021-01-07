//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    struct SubMenu {
        enum Kind {
            case add
            case others
        }

        let kind: Kind
        let isInline: Bool
        let children: [MenuElement]
    }
}
