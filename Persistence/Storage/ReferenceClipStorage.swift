//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift

// swiftlint:disable first_where

public class ReferenceClipStorage {
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

    public func readAllClips() -> Result<[ReferenceClip], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let clips = realm.objects(ReferenceClipObject.self)
            .map { ReferenceClip.make(by: $0) }
        return .success(Array(clips))
    }

    public func readClip(havingUrl url: URL) -> Result<ReferenceClip?, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }

        guard let clip = realm.objects(ReferenceClipObject.self).filter("url = '\(url.absoluteString)'").first else {
            return .success(nil)
        }

        return .success(ReferenceClip.make(by: clip))
    }

    public func readAllTags() -> Result<[ReferenceTag], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(ReferenceTagObject.self)
            .map { ReferenceTag.make(by: $0) }
        return .success(Array(tags))
    }

    // MARK: Create

    public func create(clip: ReferenceClip) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let obj = ReferenceClipObject()
        obj.id = clip.id
        obj.url = clip.url?.absoluteString
        obj.descriptionText = clip.description
        clip.tags.forEach { tag in
            let tagObj = ReferenceTagObject()
            tagObj.id = tag.id
            tagObj.name = tag.name
            obj.tags.append(tagObj)
        }
        obj.isHidden = clip.isHidden
        obj.registeredAt = clip.registeredDate
        obj.isDirty = clip.isDirty

        realm.add(obj, update: .modified)

        return .success(())
    }

    public func create(tag: ReferenceTag) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let obj = ReferenceTagObject()
        obj.id = tag.id
        obj.name = tag.name
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

    public func updateClips(having clipIds: [ReferenceClip.Identity], byAddingTagsHaving tagIds: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = tagIds.compactMap { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
        let clips = clipIds.compactMap { realm.object(ofType: ReferenceClipObject.self, forPrimaryKey: $0) }

        for clip in clips {
            for tag in tags {
                guard !clip.tags.contains(tag) else { continue }
                clip.tags.append(tag)
            }
        }

        return .success(())
    }

    public func updateClips(having clipIds: [ReferenceClip.Identity], byDeletingTagsHaving tagIds: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = tagIds.compactMap { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
        let clips = clipIds.compactMap { realm.object(ofType: ReferenceClipObject.self, forPrimaryKey: $0) }

        for clip in clips {
            for tag in tags {
                guard let index = clip.tags.firstIndex(of: tag) else { continue }
                clip.tags.remove(at: index)
            }
        }

        return .success(())
    }

    public func updateClips(having clipIds: [ReferenceClip.Identity], byReplacingTagsHaving tagIds: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = tagIds.compactMap { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
        let clips = clipIds.compactMap { realm.object(ofType: ReferenceClipObject.self, forPrimaryKey: $0) }

        for clip in clips {
            clip.tags.removeAll()
            tags.forEach { clip.tags.append($0) }
        }

        return .success(())
    }

    public func updateClips(having clipIds: [ReferenceClip.Identity], byUpdatingDirty isDirty: Bool) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }
        for clip in clipIds.compactMap({ realm.object(ofType: ReferenceClipObject.self, forPrimaryKey: $0) }) {
            clip.isDirty = isDirty
        }
        return .success(())
    }

    // MARK: Delete

    public func deleteClips(having ids: [ReferenceClip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: ReferenceClipObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }

    public func deleteTags(having ids: [ReferenceTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: ReferenceTagObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }
}
