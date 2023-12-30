//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain

enum Route {}

extension Route {
    struct AlbumClipList: Hashable {
        let albumId: Album.ID
    }
}

extension Route {
    struct ClipItemPage: Hashable {
        let clips: [Domain.Clip]
        let clipItem: Domain.ClipItem
    }
}
