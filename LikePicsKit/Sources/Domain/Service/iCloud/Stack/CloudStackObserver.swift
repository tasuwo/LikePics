//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ObjectID {}

public protocol CloudStackObserver: AnyObject {
    func didRemoteChangedTags(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID])
}
