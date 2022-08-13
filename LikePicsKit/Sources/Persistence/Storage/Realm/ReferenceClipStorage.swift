//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation
import RealmSwift

// swiftlint:disable contains_over_filter_is_empty

public class ReferenceClipStorage {
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

extension ReferenceClipStorage: ReferenceClipStorageProtocol {
    // MARK: - ReferenceClipStorageProtocol

    public var isInTransaction: Bool {
        return self.realm?.isInWriteTransaction ?? false
    }

    public func beginTransaction() throws {
        if let realm = self.realm, realm.isInWriteTransaction {
            realm.cancelWrite()
        }
        self.realm = try Realm(configuration: self.configuration)
        self.realm?.beginWrite()
    }

    public func commitTransaction() throws {
        guard let realm = self.realm else { return }
        try realm.commitWrite()
    }

    public func cancelTransactionIfNeeded() {
        defer { self.realm = nil }
        guard let realm = self.realm, realm.isInWriteTransaction else { return }
        realm.cancelWrite()
    }

    // MARK: Read

    public func readAllDirtyTags() -> Result<[ReferenceTag], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(ReferenceTagObject.self)
            .filter { $0.isDirty }
            .map { ReferenceTag.make(by: $0) }
        return .success(Array(tags))
    }

    public func readAllTags() -> Result<[ReferenceTag], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(ReferenceTagObject.self)
            .map { ReferenceTag.make(by: $0) }
        return .success(Array(tags))
    }

    public func readAllTags(having ids: Set<Domain.Tag.Identity>) -> Result<[Domain.ReferenceTag], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(ReferenceTagObject.self)
            .filter { ids.contains($0.id) }
            .map { ReferenceTag.make(by: $0) }
        return .success(Array(tags))
    }

    public func readAllDirtyAlbums() -> Result<[ReferenceAlbum], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(ReferenceAlbumObject.self)
            .sorted(byKeyPath: "index")
            .filter { $0.isDirty }
            .map { ReferenceAlbum.make(by: $0) }
        return .success(Array(tags))
    }

    public func readAllAlbums() -> Result<[ReferenceAlbum], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(ReferenceAlbumObject.self)
            .sorted(byKeyPath: "index")
            .map { ReferenceAlbum.make(by: $0) }
        return .success(Array(tags))
    }

    public func readAllAlbums(having ids: Set<Domain.Album.Identity>) -> Result<[Domain.ReferenceAlbum], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let albums = realm.objects(ReferenceAlbumObject.self)
            .sorted(byKeyPath: "index")
            .filter { ids.contains($0.id) }
            .map { ReferenceAlbum.make(by: $0) }
        return .success(Array(albums))
    }

    // MARK: Create

    public func create(tag: ReferenceTag) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: tag.id) != nil {
            return .failure(.duplicated)
        }

        if realm.objects(ReferenceTagObject.self).filter("name = '\(tag.name)'").isEmpty == false {
            return .failure(.duplicated)
        }

        let obj = ReferenceTagObject()
        obj.id = tag.id
        obj.name = tag.name
        obj.clipCount = tag.clipCount
        obj.isDirty = tag.isDirty

        realm.add(obj, update: .modified)

        return .success(())
    }

    public func create(album: ReferenceAlbum) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if realm.object(ofType: ReferenceAlbumObject.self, forPrimaryKey: album.id) != nil {
            return .failure(.duplicated)
        }

        if realm.objects(ReferenceAlbumObject.self).filter("name = '\(album.title)'").isEmpty == false {
            return .failure(.duplicated)
        }

        let albums = realm.objects(ReferenceAlbumObject.self)
            .sorted(byKeyPath: "index")

        let obj = ReferenceAlbumObject()
        obj.id = album.id
        obj.index = 1
        obj.title = album.title
        obj.isHidden = album.isHidden
        obj.registeredDate = album.registeredDate
        obj.updatedDate = album.updatedDate
        obj.isDirty = album.isDirty

        realm.add(obj, update: .modified)

        var currentIndex = 2
        albums.forEach {
            $0.index = currentIndex
            currentIndex += 1
        }

        return .success(())
    }

    // MARK: Update

    public func updateTag(having id: ReferenceTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: id)
        tag?.name = name

        return .success(())
    }

    public func updateTag(having id: ReferenceTag.Identity, byHiding isHidden: Bool) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: id)
        tag?.isHidden = isHidden

        return .success(())
    }

    public func updateTag(having id: Domain.ReferenceTag.Identity, clipCountTo clipCount: Int?) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: id)
        tag?.clipCount = clipCount

        return .success(())
    }

    public func updateTags(having ids: [ReferenceTag.Identity], toDirty isDirty: Bool) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = ids
            .map { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
        tags.forEach { $0?.isDirty = isDirty }

        return .success(())
    }

    public func updateAlbum(having id: ReferenceAlbum.Identity, titleTo title: String, updatedAt updatedDate: Date) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let album = realm.object(ofType: ReferenceAlbumObject.self, forPrimaryKey: id)
        album?.title = title
        album?.updatedDate = updatedDate

        return .success(())
    }

    public func updateAlbum(having id: ReferenceAlbum.Identity, byHiding isHidden: Bool, updatedAt updatedDate: Date) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: ReferenceAlbumObject.self, forPrimaryKey: id)
        tag?.isHidden = isHidden
        tag?.updatedDate = updatedDate

        return .success(())
    }

    public func updateAlbum(having id: ReferenceAlbum.Identity, updatedAt updatedDate: Date) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: ReferenceAlbumObject.self, forPrimaryKey: id)
        tag?.updatedDate = updatedDate

        return .success(())
    }

    public func updateAlbums(byReordering albumIds: [ReferenceAlbum.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let albums = realm.objects(ReferenceAlbumObject.self)
        guard Set(albums.compactMap({ $0.id })) == Set(albumIds) else {
            return .failure(.invalidParameter)
        }

        var currentIndex = 1
        for albumId in albumIds {
            guard let target = albums.first(where: { $0.id == albumId }) else {
                continue
            }
            target.index = currentIndex
            currentIndex += 1
        }

        return .success(())
    }

    public func updateAlbums(having ids: [ReferenceAlbum.Identity], toDirty isDirty: Bool) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let albums = ids
            .map { realm.object(ofType: ReferenceAlbumObject.self, forPrimaryKey: $0) }
        albums.forEach { $0?.isDirty = isDirty }

        return .success(())
    }

    // MARK: Delete

    public func deleteTags(having ids: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }

    public func deleteAlbums(having ids: [ReferenceAlbum.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: ReferenceAlbumObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }
}
