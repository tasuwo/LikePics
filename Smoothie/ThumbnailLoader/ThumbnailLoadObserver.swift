//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ThumbnailLoadObserver: AnyObject {
    func didStartLoading(_ request: ThumbnailRequest)
    func didFailedToLoad(_ request: ThumbnailRequest)
    func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage)
}
