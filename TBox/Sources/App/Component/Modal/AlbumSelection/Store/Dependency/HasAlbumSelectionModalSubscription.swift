//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol HasAlbumSelectionModalSubscription {
    var albumSelectionCompleted: (Album.Identity?) -> Void { get }
}
