//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public extension ClipCollection {
    struct IndexPath: Equatable, Codable {
        public let clipIndex: Int
        public let itemIndex: Int

        public init(clipIndex: Int, itemIndex: Int) {
            self.clipIndex = clipIndex
            self.itemIndex = itemIndex
        }
    }
}
