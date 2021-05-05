//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    enum Layout: Equatable {
        case waterfall
        case grid

        var isSingleThumbnail: Bool { self == .grid }
    }
}
