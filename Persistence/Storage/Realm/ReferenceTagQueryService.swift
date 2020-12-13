//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift

public class ReferenceTagQueryService {
    public struct Configuration {
        let realmConfiguration: Realm.Configuration
    }

    let configuration: Realm.Configuration
    private let logger: TBoxLoggable
    private var realm: Realm?

    // MARK: - Lifecycle

    public init(config: ReferenceClipStorage.Configuration, logger: TBoxLoggable) throws {
        self.configuration = config.realmConfiguration
        self.logger = logger
    }
}

extension ReferenceTagQueryService: TagQueryServiceProtocol {
    // MARK: - TagQueryServiceProtocol

    public func queryTags() -> Result<TagListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        return .success(RealmReferenceTagListQuery(results: realm.objects(ReferenceTagObject.self)))
    }
}
