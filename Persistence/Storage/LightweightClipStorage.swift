//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift

public class LightweightClipStorage {
    public enum StorageConfiguration {
        static let realmFileName = "lightweight-clips.realm"

        public static func makeConfiguration() -> Realm.Configuration {
            var configuration = Realm.Configuration(
                schemaVersion: 0,
                migrationBlock: LightweightClipStorageMigrationService.migrationBlock,
                deleteRealmIfMigrationNeeded: false
            )

            if let appGroupIdentifier = Constants.appGroupIdentifier,
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            {
                configuration.fileURL = directory.appendingPathComponent(self.realmFileName)
            } else {
                fatalError("Unable to resolve realm file url.")
            }

            return configuration
        }
    }

    let configuration: Realm.Configuration

    private let logger: TBoxLoggable
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.LightweightClipStorage")

    private var realm: Realm?

    // MARK: - Lifecycle

    init(realmConfiguration: Realm.Configuration, logger: TBoxLoggable) throws {
        self.configuration = realmConfiguration
        self.logger = logger
    }

    public convenience init(logger: TBoxLoggable) throws {
        try self.init(realmConfiguration: StorageConfiguration.makeConfiguration(),
                      logger: logger)
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

        realm.add(obj)

        return .success(())
    }

    public func create(tag: LightweightTag) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let obj = LightweightTagObject()
        obj.id = tag.id
        obj.name = tag.name

        realm.add(obj)

        return .success(())
    }

    // MARK: Update

    public func updateTag(having id: LightweightTag.Identity, nameTo name: String) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id)
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
