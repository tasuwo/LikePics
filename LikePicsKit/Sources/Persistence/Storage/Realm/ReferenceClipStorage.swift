//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
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

    // MARK: Delete

    public func deleteTags(having ids: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }
}
