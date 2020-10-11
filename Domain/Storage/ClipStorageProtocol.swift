//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public enum ClipStorageError: Int, Error {
    case duplicated = 0
    case notFound
    case invalidParameter
    case internalError
}

/// @mockable
public protocol ClipQueryServiceProtocol {
    func queryClip(having id: Clip.Identity) -> Result<ClipQuery, ClipStorageError>
    func queryAllClips() -> Result<ClipListQuery, ClipStorageError>
    func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError>
    func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError>
    func queryClips(tagged tag: Tag) -> Result<ClipListQuery, ClipStorageError>
    func queryAlbum(having id: Album.Identity) -> Result<AlbumQuery, ClipStorageError>
    func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError>
    func queryAllTags() -> Result<TagListQuery, ClipStorageError>
}

/// @mockable
public protocol ClipStorageProtocol {
    // MARK: Create

    func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError>

    func create(tagWithName name: String) -> Result<Tag, ClipStorageError>

    func create(albumWithTitle: String) -> Result<Album, ClipStorageError>

    // MARK: Read

    func readImageData(of item: ClipItem) -> Result<Data, ClipStorageError>

    func readThumbnailData(of item: ClipItem) -> Result<Data, ClipStorageError>

    // MARK: Update

    func updateClips(having ids: [Clip.Identity], byHiding: Bool) -> Result<[Clip], ClipStorageError>

    func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>

    func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError>

    func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>

    func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError>

    func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Album, ClipStorageError>

    func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Tag, ClipStorageError>

    // MARK: Delete

    func deleteClips(having ids: [Clip.Identity]) -> Result<[Clip], ClipStorageError>

    func delete(_ clipItem: ClipItem) -> Result<ClipItem, ClipStorageError>

    func deleteAlbum(having id: Album.Identity) -> Result<Album, ClipStorageError>

    func deleteTags(having ids: [Tag.Identity]) -> Result<[Tag], ClipStorageError>
}

extension ClipStorageProtocol {
    public func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError> {
        self.create(clip: clip, withData: data, forced: false)
    }
}

extension ClipStorageError: ErrorCodeSource {
    public var factors: [ErrorCodeFactor] {
        return [
            .string("CSE"),
            .number(self.rawValue)
        ]
    }
}
