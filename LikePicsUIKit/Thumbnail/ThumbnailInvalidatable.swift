//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ThumbnailInvalidatable: AnyObject {
    func invalidateCache(having key: String)
}
