//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    struct AddingToAlbumRequest {
        let target: Album.Identity
        let clips: Set<Clip.Identity>
    }
}
