//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchMenuState: Equatable {
    let shouldSearchOnlyHiddenClip: Bool?
    let sort: ClipSearchSort
}
