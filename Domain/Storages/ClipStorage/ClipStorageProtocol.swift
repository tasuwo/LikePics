//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol ClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Create

    func create(clip: Clip, forced: Bool) -> Result<Clip.Identity, ClipStorageError>
    func create(tagWithName name: String) -> Result<Tag, ClipStorageError>
    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    // MARK: Update

    func updateClips(having ids: [Clip.Identity], byHiding: Bool) -> Result<[Clip], ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Album, ClipStorageError>
    func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Tag, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<[Clip], ClipStorageError>
    func deleteClipItem(having id: ClipItem.Identity) -> Result<ClipItem, ClipStorageError>
    func deleteAlbum(having id: Album.Identity) -> Result<Album, ClipStorageError>
    func deleteTags(having ids: [Tag.Identity]) -> Result<[Tag], ClipStorageError>
}
