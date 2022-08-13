//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

public enum AlbumCommandServiceError: Error {
    case duplicated
    case internalError
}

public protocol HasAlbumCommandService {
    var albumCommandService: AlbumCommandServiceProtocol { get }
}

/// @mockable
public protocol AlbumCommandServiceProtocol {
    func create(albumWithTitle title: String) -> Result<Album.Identity, AlbumCommandServiceError>
}
