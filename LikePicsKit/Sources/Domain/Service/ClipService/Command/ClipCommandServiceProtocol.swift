//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

/// @mockable
public protocol ClipCommandServiceProtocol {
    // MARK: Create

    func create(clip: ClipRecipe, withContainers containers: [ImageContainer], forced: Bool) -> Result<Clip.Identity, ClipStorageError>
    func create(tagWithName name: String) -> Result<Tag.Identity, ClipStorageError>
    func create(albumWithTitle: String) -> Result<Album.Identity, ClipStorageError>

    // MARK: Update

    func updateClips(having ids: [Clip.Identity], byHiding: Bool) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError>
    func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError>
    func updateClip(having id: Clip.Identity, byReorderingItemsHaving: [ClipItem.Identity]) -> Result<Void, ClipStorageError>
    func updateClipItems(having ids: [ClipItem.Identity], byUpdatingSiteUrl: URL?) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byReorderingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Void, ClipStorageError>
    func updateAlbum(having albumId: Album.Identity, byHiding: Bool) -> Result<Void, ClipStorageError>
    func updateAlbums(byReordering albumIds: [Album.Identity]) -> Result<Void, ClipStorageError>
    func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Void, ClipStorageError>
    func updateTag(having id: Tag.Identity, byHiding: Bool) -> Result<Void, ClipStorageError>

    func purgeClipItems(forClipHaving id: Clip.Identity) -> Result<Void, ClipStorageError>
    func mergeClipItems(
        itemIds: [ClipItem.Identity],
        tagIds: [Tag.Identity],
        siteUrl: URL?,
        isHidden: Bool,
        inClipsHaving clipIds: [Clip.Identity]
    ) -> Result<Void, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<Void, ClipStorageError>
    func deleteClipItem(_ item: ClipItem) -> Result<Void, ClipStorageError>
    func deleteAlbum(having id: Album.Identity) -> Result<Void, ClipStorageError>
    func deleteTags(having ids: [Tag.Identity]) -> Result<Void, ClipStorageError>

    // MARK: Decuplicate

    func deduplicateAlbumItem(albumId: Domain.Album.Identity, clipId: Domain.Clip.Identity)
}
