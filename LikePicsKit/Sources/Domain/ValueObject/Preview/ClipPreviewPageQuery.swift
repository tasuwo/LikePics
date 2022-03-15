//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ClipPreviewPageQuery: Equatable {
    public enum ClipCollectionSource: Equatable {
        case all
        case album(Album.Identity)
        case tag(Tag)
        case uncategorized
        case search(ClipSearchQuery)
    }

    case clips(ClipCollectionSource)
    case searchResult(ClipSearchQuery)
}
