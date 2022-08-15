//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

public class ReferenceTagQueryService {
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

extension ReferenceTagQueryService: TagQueryServiceProtocol {
    // MARK: - TagQueryServiceProtocol

    public func queryTags() -> Result<TagListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        return .success(RealmReferenceTagListQuery(results: realm.objects(ReferenceTagObject.self).sorted(by: \.name)))
    }
}
