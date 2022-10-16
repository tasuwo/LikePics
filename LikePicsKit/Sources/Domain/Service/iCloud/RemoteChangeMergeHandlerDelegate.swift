//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public protocol ObjectID {}

public protocol RemoteChangeMergeHandlerDelegate: AnyObject {
    func didRemoteChangedTags(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID])
    func didRemoteChangedAlbums(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID])
    func didRemoteChangedAlbumItems(inserted: [ObjectID], updated: [ObjectID], deleted: [ObjectID])
}
