//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumListMenuBuildable {
    static func build(for album: Album) -> [AlbumList.MenuItem]
}

enum AlbumListMenuBuilder: AlbumListMenuBuildable {
    // MARK: - AlbumListMenuBuildable

    static func build(for album: Album) -> [AlbumList.MenuItem] {
        return [
            .rename,
            album.isHidden ? .reveal : .hide,
            .delete
        ]
    }
}
