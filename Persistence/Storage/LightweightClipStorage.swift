//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift

// swiftlint:disable first_where

public class LightweightClipStorage {
    public struct Configuration {
        let realmConfiguration: Realm.Configuration
    }

    let configuration: Realm.Configuration
    private let logger: TBoxLoggable
    private var realm: Realm?

    // MARK: - Lifecycle

    public init(config: LightweightClipStorage.Configuration, logger: TBoxLoggable) throws {
        self.configuration = config.realmConfiguration
        self.logger = logger
    }
}

extension LightweightClipStorage: LightweightClipStorageProtocol {
    // MARK: - LightweightClipStorageProtocol

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

    public func existsClip(havingUrl url: URL) -> Bool? {
        guard let realm = try? Realm(configuration: self.configuration) else { return nil }

        guard realm.objects(LightweightClipObject.self).filter("url = '\(url.absoluteString)'").first != nil else {
            return false
        }

        return true
    }

    // MARK: Create

    public func create(clip: LightweightClip) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let obj = LightweightClipObject()
        obj.id = clip.id
        obj.url = clip.url?.absoluteString
        clip.tags.forEach { tag in
            let tagObj = LightweightTagObject()
            tagObj.id = tag.id
            tagObj.name = tag.name
            obj.tags.append(tagObj)
        }

        realm.add(obj, update: .modified)

        return .success(())
    }

    public func create(tag: LightweightTag) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let obj = LightweightTagObject()
        obj.id = tag.id
        obj.name = tag.name

        realm.add(obj, update: .modified)

        return .success(())
    }

    // MARK: Update

    public func updateTag(having id: LightweightTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: LightweightTagObject.self, forPrimaryKey: id)
        tag?.name = name

        return .success(())
    }

    public func updateClips(having clipIds: [LightweightClip.Identity], byAddingTagsHaving tagIds: [LightweightTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = tagIds.compactMap { realm.object(ofType: LightweightTagObject.self, forPrimaryKey: $0) }
        let clips = clipIds.compactMap { realm.object(ofType: LightweightClipObject.self, forPrimaryKey: $0) }

        for clip in clips {
            for tag in tags {
                guard !clip.tags.contains(tag) else { continue }
                clip.tags.append(tag)
            }
        }

        return .success(())
    }

    public func updateClips(having clipIds: [LightweightClip.Identity], byDeletingTagsHaving tagIds: [LightweightTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = tagIds.compactMap { realm.object(ofType: LightweightTagObject.self, forPrimaryKey: $0) }
        let clips = clipIds.compactMap { realm.object(ofType: LightweightClipObject.self, forPrimaryKey: $0) }

        for clip in clips {
            for tag in tags {
                guard let index = clip.tags.firstIndex(of: tag) else { continue }
                clip.tags.remove(at: index)
            }
        }

        return .success(())
    }

    public func updateClips(having clipIds: [LightweightClip.Identity], byReplacingTagsHaving tagIds: [LightweightTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tags = tagIds.compactMap { realm.object(ofType: LightweightTagObject.self, forPrimaryKey: $0) }
        let clips = clipIds.compactMap { realm.object(ofType: LightweightClipObject.self, forPrimaryKey: $0) }

        for clip in clips {
            clip.tags.removeAll()
            tags.forEach { clip.tags.append($0) }
        }

        return .success(())
    }

    // MARK: Delete

    public func deleteClips(having ids: [LightweightClip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: LightweightClipObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }

    public func deleteTags(having ids: [LightweightTag.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        ids
            .compactMap { realm.object(ofType: LightweightTagObject.self, forPrimaryKey: $0) }
            .forEach { realm.delete($0) }

        return .success(())
    }
}
