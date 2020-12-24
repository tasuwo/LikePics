//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipPreview {
    struct BarItem {
        enum Kind {
            case deleteOnlyImageOrClip
            case deleteClip
            case openWeb
            case add
            case back
            case info
            case share
        }

        let kind: Kind
        let isEnabled: Bool
    }
}
