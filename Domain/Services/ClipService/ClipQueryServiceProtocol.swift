//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol ClipQueryServiceProtocol {
    func existsClip(havingUrl: URL) -> Bool?
    func queryClip(having id: Clip.Identity) -> Result<ClipQuery, ClipStorageError>
    func queryAllClips() -> Result<ClipListQuery, ClipStorageError>
    func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError>
    func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError>
    func queryClips(tagged tag: Tag) -> Result<ClipListQuery, ClipStorageError>
    func queryAlbum(having id: Album.Identity) -> Result<AlbumQuery, ClipStorageError>
    func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError>
    func queryAllTags() -> Result<TagListQuery, ClipStorageError>
}
