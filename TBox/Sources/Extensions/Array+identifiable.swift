//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

extension Array where Element == Clip {
    var ids: [Clip.Identity] {
        self.map({ $0.identity })
    }
}

extension Array where Element == Tag {
    var ids: [Tag.Identity] {
        self.map({ $0.identity })
    }
}
