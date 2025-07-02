//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    public enum Layout: String, Codable, Equatable {
        case waterfall
        case grid

        public var isSingleThumbnail: Bool { self == .grid }
    }
}

extension ClipCollection.Layout {
    public var nextLayout: Self {
        switch self {
        case .grid:
            return .waterfall

        case .waterfall:
            return .grid
        }
    }
}
