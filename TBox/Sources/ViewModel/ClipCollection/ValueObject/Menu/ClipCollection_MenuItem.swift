//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    enum MenuItem {
        case addTag
        case addToAlbum
        case hide(immediately: Bool)
        case unhide
        case removeFromAlbum
        case delete
        case share
        case purge
    }
}
