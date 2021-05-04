//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ThumbnailPrefetchObserver: AnyObject {
    func didComplete(_ request: ThumbnailRequest)
}
