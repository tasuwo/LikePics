//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ThumbnailRequestUserInfo: Equatable {
    public struct Key: Equatable, Hashable {
        let rawValue: String
    }
}

public extension ThumbnailRequestUserInfo.Key {
    init(_ rawValue: String) {
        self.rawValue = rawValue as String
    }
}
