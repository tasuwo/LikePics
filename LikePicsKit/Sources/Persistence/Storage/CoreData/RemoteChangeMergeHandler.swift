//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain
import os.log

@MainActor
public let RemoteChangeMergeHandler: (NSPersistentContainer, [NSPersistentHistoryTransaction], RemoteChangeMergeHandlerDelegate) -> Void = { _, transactions, cloudStackObserver in
    var insertedTagObjectIDs = [NSManagedObjectID]()
    var updatedTagObjectIDs = [NSManagedObjectID]()
    var deletedTagObjectIDs = [NSManagedObjectID]()
    var insertedAlbumObjectIDs = [NSManagedObjectID]()
    var updatedAlbumObjectIDs = [NSManagedObjectID]()
    var deletedAlbumObjectIDs = [NSManagedObjectID]()
    var insertedAlbumItemObjectIDs = [NSManagedObjectID]()
    var updatedAlbumItemObjectIDs = [NSManagedObjectID]()
    var deletedAlbumItemObjectIDs = [NSManagedObjectID]()
    for transaction in transactions where transaction.changes != nil {
        // swiftlint:disable:next force_unwrapping
        for change in transaction.changes! {
            if change.isTagChange {
                switch change.changeType {
                case .insert:
                    insertedTagObjectIDs.append(change.changedObjectID)

                case .update:
                    updatedTagObjectIDs.append(change.changedObjectID)

                case .delete:
                    deletedTagObjectIDs.append(change.changedObjectID)

                @unknown default:
                    break
                }
            } else if change.isAlbumChange {
                switch change.changeType {
                case .insert:
                    insertedAlbumObjectIDs.append(change.changedObjectID)

                case .update:
                    updatedAlbumObjectIDs.append(change.changedObjectID)

                case .delete:
                    deletedAlbumObjectIDs.append(change.changedObjectID)

                @unknown default:
                    break
                }
            } else if change.isAlbumItemChange {
                switch change.changeType {
                case .insert:
                    insertedAlbumItemObjectIDs.append(change.changedObjectID)

                case .update:
                    updatedAlbumItemObjectIDs.append(change.changedObjectID)

                case .delete:
                    deletedAlbumItemObjectIDs.append(change.changedObjectID)

                @unknown default:
                    break
                }
            }
        }
    }

    cloudStackObserver.didRemoteChangedTags(inserted: insertedTagObjectIDs,
                                            updated: updatedTagObjectIDs,
                                            deleted: deletedTagObjectIDs)
    cloudStackObserver.didRemoteChangedAlbums(inserted: insertedAlbumObjectIDs,
                                              updated: updatedAlbumObjectIDs,
                                              deleted: deletedAlbumObjectIDs)
    cloudStackObserver.didRemoteChangedAlbumItems(inserted: insertedAlbumItemObjectIDs,
                                                  updated: updatedAlbumItemObjectIDs,
                                                  deleted: deletedAlbumItemObjectIDs)
}

private extension NSPersistentHistoryChange {
    var isTagChange: Bool {
        return self.changedObjectID.entity.name == Tag.entity().name
    }

    var isAlbumChange: Bool {
        return self.changedObjectID.entity.name == Album.entity().name
    }

    var isAlbumItemChange: Bool {
        return self.changedObjectID.entity.name == AlbumItem.entity().name
    }

    var isInsertOrUpdate: Bool {
        return self.changeType == .insert || self.changeType == .update
    }
}
