//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum ClipPreviewPageBarEvent {
    case backed
    case listed
    case infoRequested
    case played
    case playConfigRequested
    case browsed
    case addToAlbum
    case addTags
    case shared(Bool)
    case deleteClip
    case removeFromClip
    case alertPresented
}
