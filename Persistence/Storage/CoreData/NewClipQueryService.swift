//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

class NewClipQueryService {}

extension NewClipQueryService: ClipQueryServiceProtocol {
    public func readClip(havingUrl url: URL) -> Result<Domain.Clip?, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryClip(having id: Domain.Clip.Identity) -> Result<Domain.ClipQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryAlbum(having id: Domain.Album.Identity) -> Result<AlbumQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        return .failure(.internalError)
    }

    public func queryAllTags() -> Result<TagListQuery, ClipStorageError> {
        return .failure(.internalError)
    }
}
