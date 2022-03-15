//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum MenuItem {
        case addTag
        case addToAlbum
        case hide(immediately: Bool)
        case reveal
        case removeFromAlbum
        case delete
        case share
        case purge
    }
}
