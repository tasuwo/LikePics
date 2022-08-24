//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol PreviewPrefetchCancellable {
    func cancel()
}

/// @mockable
public protocol PreviewPrefetchable {
    func prefetchPreview(for item: ClipItem) -> PreviewPrefetchCancellable
}
