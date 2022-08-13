//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Common
import CoreData
import Domain

public class ClipQueryCacheService<Service: ClipQueryServiceProtocol> {
    public let internalService: Service

    private weak var allClipsQuery: ClipListQuery?

    // MARK: - Initializers

    public init(_ internalService: Service) {
        self.internalService = internalService
    }
}

extension ClipQueryCacheService: ClipQueryServiceProtocol {
    // MARK: - ClipQueryServiceProtocol

    public func searchClips(query: ClipSearchQuery) -> Result<[Domain.Clip], ClipStorageError> {
        return internalService.searchClips(query: query)
    }

    public func searchAlbums(containingTitle title: String, includesHiddenItems: Bool, limit: Int) -> Result<[Domain.Album], ClipStorageError> {
        return internalService.searchAlbums(containingTitle: title, includesHiddenItems: includesHiddenItems, limit: limit)
    }

    public func searchTags(containingName name: String, includesHiddenItems: Bool, limit: Int) -> Result<[Domain.Tag], ClipStorageError> {
        return internalService.searchTags(containingName: name, includesHiddenItems: includesHiddenItems, limit: limit)
    }

    public func readClipAndTags(for clipIds: [Domain.Clip.Identity]) -> Result<([Domain.Clip], [Domain.Tag]), ClipStorageError> {
        return internalService.readClipAndTags(for: clipIds)
    }

    public func queryClip(having id: Domain.Clip.Identity) -> Result<ClipQuery, ClipStorageError> {
        return internalService.queryClip(having: id)
    }

    public func queryClipItems(inClipHaving id: Domain.Clip.Identity) -> Result<ClipItemListQuery, ClipStorageError> {
        return internalService.queryClipItems(inClipHaving: id)
    }

    public func queryClipItem(having id: Domain.ClipItem.Identity) -> Result<ClipItemQuery, ClipStorageError> {
        return internalService.queryClipItem(having: id)
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        if let query = self.allClipsQuery {
            return .success(query)
        }

        let result = internalService.queryAllClips()

        if let query = result.successValue {
            self.allClipsQuery = query
        }

        return result
    }

    public func queryAllListingClips() -> Result<ListingClipListQuery, ClipStorageError> {
        return internalService.queryAllListingClips()
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        return internalService.queryUncategorizedClips()
    }

    public func queryTags(forClipHaving clipId: Domain.Clip.Identity) -> Result<TagListQuery, ClipStorageError> {
        return internalService.queryTags(forClipHaving: clipId)
    }

    public func queryClips(query: ClipSearchQuery) -> Result<ClipListQuery, ClipStorageError> {
        return internalService.queryClips(query: query)
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        return internalService.queryClips(tagged: tag)
    }

    public func queryClips(tagged tagId: Domain.Tag.Identity) -> Result<ClipListQuery, ClipStorageError> {
        return internalService.queryClips(tagged: tagId)
    }

    public func queryAlbum(having id: Domain.Album.Identity) -> Result<AlbumQuery, ClipStorageError> {
        return internalService.queryAlbum(having: id)
    }

    public func queryAlbums(containingClipHavingClipId id: Domain.Clip.Identity) -> Result<ListingAlbumTitleListQuery, ClipStorageError> {
        return internalService.queryAlbums(containingClipHavingClipId: id)
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        return internalService.queryAllAlbums()
    }

    public func queryAllAlbumTitles() -> Result<ListingAlbumTitleListQuery, ClipStorageError> {
        return internalService.queryAllAlbumTitles()
    }

    public func queryAllTags() -> Result<TagListQuery, ClipStorageError> {
        return internalService.queryAllTags()
    }
}

extension ClipQueryCacheService: TagQueryServiceProtocol {
    public func queryTags() -> Result<TagListQuery, ClipStorageError> {
        return internalService.queryAllTags()
    }
}
