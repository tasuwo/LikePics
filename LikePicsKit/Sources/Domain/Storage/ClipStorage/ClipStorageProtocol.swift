//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

/// @mockable
public protocol ClipStorageProtocol {
    // MARK: Transaction

    var isInTransaction: Bool { get }
    func beginTransaction() throws
    func commitTransaction() throws
    func cancelTransactionIfNeeded() throws

    // MARK: Read

    func readAllClips() -> Result<[Clip], ClipStorageError>
    func readAllTags() -> Result<[Tag], ClipStorageError>
    func readTags(forClipHaving clipId: Clip.Identity) -> Result<[Tag], ClipStorageError>
    func readClipItems(having: [ClipItem.Identity]) -> Result<[ClipItem], ClipStorageError>
    func readAlbumIds(containsClipsHaving: [Clip.Identity]) -> Result<[Album.Identity], ClipStorageError>

    // MARK: Create

    func create(clip: ClipRecipe) -> Result<Clip, ClipStorageError>
    func create(tagWithName name: String) -> Result<Tag, ClipStorageError>
    func create(_ tag: Tag) -> Result<Tag, ClipStorageError>
    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    // MARK: Update

    func updateClips(having ids: [Clip.Identity], byHiding: Bool) -> Result<[Clip], ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>
    func updateClip(having clipId: Clip.Identity, byReorderingItemsHaving itemIds: [ClipItem.Identity]) -> Result<Void, ClipStorageError>
    func updateClipItems(having ids: [ClipItem.Identity], byUpdatingSiteUrl: URL?) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byReorderingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Album, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byHiding: Bool) -> Result<Album, ClipStorageError>
    func updateAlbums(byReordering albumIds: [Album.Identity]) -> Result<Void, ClipStorageError>
    func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Tag, ClipStorageError>
    func updateTag(having id: Tag.Identity, byHiding: Bool) -> Result<Tag, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<[Clip], ClipStorageError>
    func deleteClipItem(having id: ClipItem.Identity) -> Result<ClipItem, ClipStorageError>
    func deleteAlbum(having id: Album.Identity) -> Result<Album, ClipStorageError>
    func deleteTags(having ids: [Tag.Identity]) -> Result<[Tag], ClipStorageError>
    func deleteAll() -> Result<Void, ClipStorageError>

    // MARK: Deduplicate

    func deduplicateTag(for id: ObjectID) -> [Domain.Tag.Identity]
    func deduplicateAlbumItem(for id: ObjectID)
}
