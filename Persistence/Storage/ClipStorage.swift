//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

public class ClipStorage {
    public enum StorageConfiguration {
        static let realmFileName = "clips.realm"

        public static func makeConfiguration() -> Realm.Configuration {
            var configuration = Realm.Configuration(
                schemaVersion: 2,
                migrationBlock: ClipStorageMigrationService.migrationBlock,
                deleteRealmIfMigrationNeeded: false
            )

            if let appGroupIdentifier = Constants.appGroupIdentifier,
                let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
            {
                configuration.fileURL = directory.appendingPathComponent(self.realmFileName)
            } else {
                // TODO: Error handling
            }

            return configuration
        }
    }

    private let configuration: Realm.Configuration
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.queue")

    // MARK: - Lifecycle

    public init(realmConfiguration: Realm.Configuration) {
        self.configuration = realmConfiguration
    }

    public convenience init() {
        self.init(realmConfiguration: StorageConfiguration.makeConfiguration())
    }

    // MARK: - Methods

    private static func makeClippedImage(_ imageUrl: URL, clipUrl: URL, data: Data) -> ClippedImageObject {
        let object = ClippedImageObject()
        object.clipUrl = clipUrl.absoluteString
        object.imageUrl = imageUrl.absoluteString
        object.image = data
        object.key = object.makeKey()
        return object
    }
}

extension ClipStorage: ClipStorageProtocol {
    // MARK: - ClipStorageProtocol

    public func create(clip: Clip, withData data: [(URL, Data)], forced: Bool) -> Result<Void, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard data.count == Set(data.map { $0.0 }).count else {
                return .failure(.invalidParameter)
            }

            // Check duplication

            var duplicatedClip: ClipObject?
            if let clipObject = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) {
                if forced {
                    duplicatedClip = clipObject
                } else {
                    return .failure(.duplicated)
                }
            }

            let duplicatedClippedImages = data
                .map { $0.0 }
                .map { ClippedImageObject.makeKey(byUrl: $0, clipUrl: clip.url) }
                .compactMap { realm.object(ofType: ClippedImageObject.self, forPrimaryKey: $0) }
            if !forced, !duplicatedClippedImages.isEmpty {
                return .failure(.duplicated)
            }

            // Prepare new objects

            let newClip = clip.asManagedObject()
            if let oldClip = duplicatedClip {
                newClip.registeredAt = oldClip.registeredAt
            }
            let newClippedImages = data
                .map { Self.makeClippedImage($0.0, clipUrl: clip.url, data: $0.1) }

            // Check remove targets

            var shouldDeleteClipItems: [ClipItemObject] = []
            if let oldClip = duplicatedClip {
                shouldDeleteClipItems = oldClip.items
                    .filter { oldItem in !newClip.items.contains(where: { $0.makeKey() == oldItem.makeKey() }) }
            }

            let shouldDeleteImages = shouldDeleteClipItems
                .flatMap { [(true, $0), (false, $0)] }
                .map { ClippedImageObject.makeImageKey(ofItem: $0.1, forThumbnail: $0.0) }
                .compactMap { realm.object(ofType: ClippedImageObject.self, forPrimaryKey: $0) }

            // Delete

            let updatePolicy: Realm.UpdatePolicy = forced ? .modified : .error
            do {
                try realm.write {
                    shouldDeleteClipItems.forEach { item in
                        realm.delete(item)
                    }
                    shouldDeleteImages.forEach { image in
                        realm.delete(image)
                    }
                    realm.add(newClip, update: updatePolicy)
                    newClippedImages.forEach { image in
                        realm.add(image, update: updatePolicy)
                    }
                }
                return .success(())
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func readAllClips() -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }
            return .success(realm.objects(ClipObject.self).map { Clip.make(by: $0) })
        }
    }

    public func readClip(ofUrl url: URL) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
                return .failure(.notFound)
            }

            return .success(.make(by: clip))
        }
    }

    public func updateItems(inClipOfUrl url: URL, to items: [ClipItem]) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
                return .failure(.notFound)
            }

            do {
                try realm.write {
                    realm.delete(clip.items)
                    clip.items.append(objectsIn: items.map { $0.asManagedObject() })
                }
                return .success(.make(by: clip))
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func removeClip(ofUrl url: URL) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
                return .failure(.notFound)
            }
            let removeTarget = Clip.make(by: clip)

            // NOTE: Delete only found objects.
            let clipItems = clip.items
                .map { $0.makeKey() }
                .compactMap { realm.object(ofType: ClipItemObject.self, forPrimaryKey: $0) }

            // NOTE: Delete only found objects.
            let clippedImages = clip.items
                .flatMap { [(true, $0), (false, $0)] }
                .map { ClippedImageObject.makeImageKey(ofItem: $0.1, forThumbnail: $0.0) }
                .compactMap { realm.object(ofType: ClippedImageObject.self, forPrimaryKey: $0) }

            do {
                try realm.write {
                    realm.delete(clippedImages)
                    realm.delete(clipItems)
                    realm.delete(clip)
                }
                return .success(removeTarget)
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func removeClipItem(_ item: ClipItem) -> Result<ClipItem, ClipStorageError> {
        // TODO: Update clipItemIndex

        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            let primaryKey = item.asManagedObject().makeKey()
            guard let item = realm.object(ofType: ClipItemObject.self, forPrimaryKey: primaryKey) else {
                return .failure(.notFound)
            }
            let removeTarget = ClipItem.make(by: item)

            // NOTE: Delete only found objects.
            let clippedImages = [(true, item), (false, item)]
                .map { ClippedImageObject.makeImageKey(ofItem: $0.1, forThumbnail: $0.0) }
                .compactMap { realm.object(ofType: ClippedImageObject.self, forPrimaryKey: $0) }

            do {
                try realm.write {
                    realm.delete(clippedImages)
                    realm.delete(item)
                }
                return .success(removeTarget)
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func getImageData(ofUrl url: URL, forClipUrl clipUrl: URL) -> Result<Data, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            let primaryKey = "\(clipUrl.absoluteString)-\(url.absoluteString)"
            guard let clippedImage = realm.object(ofType: ClippedImageObject.self, forPrimaryKey: primaryKey) else {
                return .failure(.notFound)
            }

            return .success(clippedImage.image)
        }
    }
}
