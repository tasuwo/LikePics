//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

/// @mockable
public protocol ReferenceClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Read

    func readAllDirtyTags() -> Result<[ReferenceTag], ClipStorageError>
    func readAllTags() -> Result<[ReferenceTag], ClipStorageError>
    func readAllTags(having ids: Set<Tag.Identity>) -> Result<[ReferenceTag], ClipStorageError>
    func readAllDirtyAlbums() -> Result<[ReferenceAlbum], ClipStorageError>
    func readAllAlbums() -> Result<[ReferenceAlbum], ClipStorageError>
    func readAllAlbums(having ids: Set<ReferenceAlbum.Identity>) -> Result<[ReferenceAlbum], ClipStorageError>

    // MARK: Create

    func create(tag: ReferenceTag) -> Result<Void, ClipStorageError>
    func create(album: ReferenceAlbum) -> Result<Void, ClipStorageError>

    // MARK: Update

    func updateTag(having id: ReferenceTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError>
    func updateTag(having id: ReferenceTag.Identity, byHiding isHidden: Bool) -> Result<Void, ClipStorageError>
    func updateTag(having id: ReferenceTag.Identity, clipCountTo clipCount: Int?) -> Result<Void, ClipStorageError>
    func updateTags(having ids: [ReferenceTag.Identity], toDirty isDirty: Bool) -> Result<Void, ClipStorageError>
    func updateAlbum(having id: ReferenceAlbum.Identity, titleTo title: String, updatedAt updatedDate: Date) -> Result<Void, ClipStorageError>
    func updateAlbum(having id: ReferenceAlbum.Identity, byHiding isHidden: Bool, updatedAt updatedDate: Date) -> Result<Void, ClipStorageError>
    func updateAlbums(byReordering albumIds: [ReferenceAlbum.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbums(having ids: [ReferenceAlbum.Identity], toDirty isDirty: Bool) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func deleteTags(having ids: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError>
    func deleteAlbums(having ids: [ReferenceAlbum.Identity]) -> Result<Void, ClipStorageError>
}
