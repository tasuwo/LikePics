//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

public class ReferenceAlbumQueryService {
    public struct Configuration {
        let realmConfiguration: Realm.Configuration
    }

    let configuration: Realm.Configuration
    private var realm: Realm?

    // MARK: - Lifecycle

    public init(config: ReferenceClipStorage.Configuration) throws {
        self.configuration = config.realmConfiguration
    }
}

extension ReferenceAlbumQueryService: ListingAlbumTitleQueryServiceProtocol {
    // MARK: - ListingAlbumTitleQueryServiceProtocol

    public func queryAllAlbumTitles() -> Result<ListingAlbumTitleListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        return .success(RealmReferenceAlbumListQuery(results: realm.objects(ReferenceAlbumObject.self).sorted(by: \.index)))
    }
}
