//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public extension ClipCollection {
    enum Layout: String, Codable, Equatable {
        case waterfall
        case grid

        public var isSingleThumbnail: Bool { self == .grid }
    }
}

public extension ClipCollection.Layout {
    var nextLayout: Self {
        switch self {
        case .grid:
            return .waterfall

        case .waterfall:
            return .grid
        }
    }
}
