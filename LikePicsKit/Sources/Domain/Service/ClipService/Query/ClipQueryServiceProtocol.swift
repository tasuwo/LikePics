//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

/// @mockable
public protocol ClipQueryServiceProtocol {
    func searchClips(query: ClipSearchQuery) -> Result<[Clip], ClipStorageError>
    func searchAlbums(containingTitle title: String, includesHiddenItems: Bool, limit: Int) -> Result<[Album], ClipStorageError>
    func searchTags(containingName name: String, includesHiddenItems: Bool, limit: Int) -> Result<[Tag], ClipStorageError>

    func readClipAndTags(for clipIds: [Clip.Identity]) -> Result<([Clip], [Tag]), ClipStorageError>

    func queryClip(having id: Clip.Identity) -> Result<ClipQuery, ClipStorageError>
    func queryClipItems(inClipHaving id: Clip.Identity) -> Result<ClipItemListQuery, ClipStorageError>
    func queryClipItem(having id: ClipItem.Identity) -> Result<ClipItemQuery, ClipStorageError>
    func queryAllClips() -> Result<ClipListQuery, ClipStorageError>
    func queryAllListingClips() -> Result<ListingClipListQuery, ClipStorageError>
    func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError>
    func queryTags(forClipHaving clipId: Clip.Identity) -> Result<TagListQuery, ClipStorageError>
    func queryClips(query: ClipSearchQuery) -> Result<ClipListQuery, ClipStorageError>
    func queryClips(tagged tag: Tag) -> Result<ClipListQuery, ClipStorageError>
    func queryClips(tagged tagId: Tag.Identity) -> Result<ClipListQuery, ClipStorageError>
    func queryAlbum(having id: Album.Identity) -> Result<AlbumQuery, ClipStorageError>
    func queryAlbums(containingClipHavingClipId id: Clip.Identity) -> Result<ListingAlbumTitleListQuery, ClipStorageError>
    func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError>
    func queryAllAlbumTitles() -> Result<ListingAlbumTitleListQuery, ClipStorageError>
    func queryAllTags() -> Result<TagListQuery, ClipStorageError>
}
