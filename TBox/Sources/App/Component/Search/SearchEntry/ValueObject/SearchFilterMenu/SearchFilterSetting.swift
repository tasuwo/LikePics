//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchFilterSetting: Equatable {
    static let `default`: Self = .init(isHidden: nil, sort: .createdDate(.ascend))

    let isHidden: Bool?
    let sort: ClipSearchSort
}
