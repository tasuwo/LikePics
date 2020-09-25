//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

extension ClipStorage: ClipQueryServiceProtocol {
    // MARK: - ClipQueryServiceProtocol

    public func queryClip(having url: URL) -> Result<ClipQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
            return .failure(.notFound)
        }

        return .success(RealmClipQuery(object: clip))
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }
        return .success(RealmClipListQuery(results: realm.objects(ClipObject.self)))
    }

    public func queryClips(matchingKeywords keywords: [String]) -> Result<ClipListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        let filter = keywords.reduce(into: "") { result, keyword in
            let predicate = "url CONTAINS[cd] '\(keyword)'"
            if result.isEmpty {
                result = predicate
            } else {
                result += "OR \(predicate)"
            }
        }
        let results = realm.objects(ClipObject.self).filter(filter)

        return .success(RealmClipListQuery(results: results))
    }

    public func queryAllAlbums() -> Result<AlbumListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }
        return .success(RealmAlbumListQuery(results: realm.objects(AlbumObject.self)))
    }

    public func queryAllTags() -> Result<TagListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }
        return .success(RealmTagListQuery(results: realm.objects(TagObject.self)))
    }
}
