//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    enum Layout: String, Codable, Equatable {
        case waterfall
        case grid

        var isSingleThumbnail: Bool { self == .grid }
    }
}

extension ClipCollection.Layout {
    var nextLayout: Self {
        switch self {
        case .grid:
            return .waterfall

        case .waterfall:
            return .grid
        }
    }
}
