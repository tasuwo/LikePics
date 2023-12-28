//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain

enum Route {}

extension Route {
    struct ClipList: Hashable {
        let clips: [Clip]
    }
}

extension Route {
    struct ClipItem: Hashable {
        let clipItem: Domain.ClipItem
    }
}
