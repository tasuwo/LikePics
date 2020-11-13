//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

// swiftlint:disable first_where

extension ClipStorage: ClipQueryServiceProtocol {
    // MARK: - ClipQueryServiceProtocol

    public func existsClip(havingUrl url: URL) -> Bool? {
        guard let realm = try? Realm(configuration: self.configuration) else { return nil }

        guard realm.objects(ClipObject.self).filter("url = '\(url.absoluteString)'").first != nil else {
            return false
        }

        return true
    }

    public func queryClip(having id: Domain.Clip.Identity) -> Result<ClipQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }

        return .success(RealmClipQuery(object: clip))
    }

    public func queryAllClips() -> Result<ClipListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }
        return .success(RealmClipsResultQuery(results: realm.objects(ClipObject.self)))
    }

    public func queryUncategorizedClips() -> Result<ClipListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }
        let results = realm.objects(ClipObject.self).filter("tags.@count == 0")
        return .success(RealmClipsResultQuery(results: results))
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

        return .success(RealmClipsResultQuery(results: results))
    }

    public func queryClips(tagged tag: Domain.Tag) -> Result<ClipListQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tag.identity) else {
            return .failure(.notFound)
        }

        return .success(RealmLinkingClipsQuery(results: tagObj.clips))
    }

    public func queryAlbum(having id: Domain.Album.Identity) -> Result<AlbumQuery, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }

        return .success(RealmAlbumQuery(object: album))
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
