//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

public protocol HasListingAlbumTitleQueryService {
    var listingAlbumTitleQueryService: ListingAlbumTitleQueryServiceProtocol { get }
}

public protocol ListingAlbumTitleQueryServiceProtocol {
    func queryAllAlbumTitles() -> Result<ListingAlbumTitleListQuery, ClipStorageError>
}
