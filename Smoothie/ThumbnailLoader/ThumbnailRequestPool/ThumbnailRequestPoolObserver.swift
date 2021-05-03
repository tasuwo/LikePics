//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol ThumbnailRequestPoolObserver: AnyObject {
    func didComplete(_ pool: ThumbnailRequestPool)
}
