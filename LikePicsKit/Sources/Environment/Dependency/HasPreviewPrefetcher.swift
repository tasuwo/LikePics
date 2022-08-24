//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain

public protocol HasPreviewPrefetcher {
    var previewPrefetcher: PreviewPrefetchable { get }
}
