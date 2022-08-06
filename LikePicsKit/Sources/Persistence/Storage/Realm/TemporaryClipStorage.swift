//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

public class TemporaryClipStorage {
    public struct Configuration {
        let realmConfiguration: Realm.Configuration
    }

    let configuration: Realm.Configuration
    private var realm: Realm?

    // MARK: - Lifecycle

    public init(config: TemporaryClipStorage.Configuration) throws {
        self.configuration = config.realmConfiguration
    }
}

extension TemporaryClipStorage: TemporaryClipStorageProtocol {
    // MARK: - ClipStorageProtocol

    // MARK: Transaction

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

    public func readAllClips() -> Result<[ClipRecipe], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let clips = realm.objects(ClipObject.self)
            .map { Domain.Clip.make(by: $0) }
        return .success(Array(clips))
    }

    // MARK: Create

    public func create(clip: ClipRecipe) -> Result<ClipRecipe, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        // Prepare new objects

        let newClip = ClipObject()
        newClip.id = clip.id.uuidString
        newClip.descriptionText = clip.description

        clip.items.forEach { item in
            let newClipItem = ClipItemObject()

            newClipItem.id = item.id.uuidString
            newClipItem.url = item.url
            newClipItem.clipId = clip.id.uuidString
            newClipItem.clipIndex = item.clipIndex
            newClipItem.imageId = item.imageId.uuidString
            newClipItem.imageFileName = item.imageFileName
            newClipItem.imageUrl = item.imageUrl
            newClipItem.imageHeight = item.imageSize.height
            newClipItem.imageWidth = item.imageSize.width
            newClipItem.imageDataSize = item.imageDataSize
            newClipItem.registeredAt = item.registeredDate
            newClipItem.updatedAt = item.updatedDate

            newClip.items.append(newClipItem)
        }

        clip.tagIds
            .map {
                let obj = TagIdObject()
                obj.id = $0.uuidString
                return obj
            }
            .forEach { newClip.tagIds.append($0) }

        newClip.dataSize = clip.dataSize
        newClip.isHidden = clip.isHidden
        newClip.registeredAt = clip.registeredDate
        newClip.updatedAt = clip.updatedDate

        // Add

        realm.add(newClip, update: .error)

        return .success(Domain.Clip.make(by: newClip))
    }

    // MARK: Delete

    public func deleteClips(having ids: [Domain.Clip.Identity]) -> Result<[ClipRecipe], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var clipObjects: [ClipObject] = []
        for clipId in ids {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.uuidString) else {
                return .failure(.notFound)
            }
            clipObjects.append(clip)
        }
        let removeTargets = clipObjects.map { Domain.Clip.make(by: $0) }

        // NOTE: Delete only found objects.
        let clipItems = clipObjects
            .flatMap { $0.items }
            .compactMap { realm.object(ofType: ClipItemObject.self, forPrimaryKey: $0.id) }

        realm.delete(clipItems)
        realm.delete(clipObjects)

        return .success(removeTargets)
    }

    public func deleteAll() -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }
        realm.deleteAll()
        return .success(())
    }
}
