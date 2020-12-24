//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipPreview {
    struct BarItem {
        enum Kind {
            case spacer
            case deleteOnlyImageOrClip
            case deleteClip
            case openWeb
            case add
            case back
            case info
        }

        let kind: Kind
        let isEnabled: Bool
    }
}
