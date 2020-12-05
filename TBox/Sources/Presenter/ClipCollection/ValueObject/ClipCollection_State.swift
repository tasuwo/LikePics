//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    struct State {
        enum Mode {
            case `default`
            case selecting
            case reordering
        }
        let clipsCount: Int
        let selectedClipsCount: Int
        let mode: Mode
    }
}
