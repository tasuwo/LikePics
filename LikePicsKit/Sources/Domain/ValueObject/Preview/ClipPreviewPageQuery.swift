//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ClipPreviewPageQuery: Equatable {
    case clips(ClipCollection.Source)
    case searchResult(ClipSearchQuery)
}
