//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import RealmSwift

// swiftlint:disable contains_over_filter_is_empty first_where file_length

public class ClipStorage {
    public enum StorageConfiguration {
        static let realmFileName = "clips.realm"

        public static func makeConfiguration() -> Realm.Configuration {
            var configuration = Realm.Configuration(
                schemaVersion: 5,
                migrationBlock: ClipStorageMigrationService.migrationBlock,
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

    private let imageStorage: ImageStorageProtocol

    private(set) var configuration: Realm.Configuration
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.queue")

    // MARK: - Lifecycle

    public init(realmConfiguration: Realm.Configuration, imageStorage: ImageStorageProtocol) throws {
        self.configuration = realmConfiguration
        self.imageStorage = imageStorage
    }

    public convenience init() throws {
        try self.init(realmConfiguration: StorageConfiguration.makeConfiguration(), imageStorage: ImageStorage())
    }
}

extension ClipStorage: ClipStorageProtocol {
    // MARK: - ClipStorageProtocol

    public func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            // Check parameters

            guard data.count == Set(data.map { $0.fileName }).count else {
                return .failure(.invalidParameter)
            }

            let containsFilesFor = { (item: ClipItem) in
                return data.contains(where: { $0.fileName == item.imageFileName })
                    && data.contains(where: { $0.fileName == item.thumbnailFileName })
            }
            guard clip.items.allSatisfy({ item in containsFilesFor(item) }) else {
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

            // Prepare new objects

            let newClip = clip.asManagedObject()
            if let oldClip = duplicatedClip {
                newClip.registeredAt = oldClip.registeredAt
            }

            // Check remove targets

            var shouldDeleteClipItems: [ClipItemObject] = []
            if let oldClip = duplicatedClip {
                shouldDeleteClipItems = oldClip.items
                    .filter { oldItem in !newClip.items.contains(where: { $0.makeKey() == oldItem.makeKey() }) }
            }

            // Delete

            let updatePolicy: Realm.UpdatePolicy = forced ? .modified : .error
            do {
                try realm.write {
                    shouldDeleteClipItems.forEach { item in
                        realm.delete(item)
                    }
                    realm.add(newClip, update: updatePolicy)
                }

                try? self.imageStorage.deleteAll(inClip: clip.url)
                try data.forEach { value in
                    try self.imageStorage.save(value.image, asName: value.fileName, inClip: clip.url)
                }

                return .success(())
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func create(tagWithName name: String) -> Result<Tag, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            if !realm.objects(TagObject.self).filter("name = '\(name)'").isEmpty {
                return .failure(.duplicated)
            }

            let obj = TagObject()
            obj.id = UUID().uuidString
            obj.name = name

            do {
                try realm.write {
                    realm.add(obj)
                }
                return .success(.make(by: obj))
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func create(albumWithTitle title: String) -> Result<Album, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            if !realm.objects(AlbumObject.self).filter("title = '\(title)'").isEmpty {
                return .failure(.duplicated)
            }

            let obj = AlbumObject()
            obj.id = UUID().uuidString
            obj.title = title
            obj.registeredAt = Date()
            obj.updatedAt = Date()

            do {
                try realm.write {
                    realm.add(obj)
                }
                return .success(Album.make(by: obj))
            } catch {
                return .failure(.internalError)
            }
        }
    }

    // MARK: Read

    public func readImageData(of item: ClipItem) -> Result<Data, ClipStorageError> {
        return self.queue.sync {
            do {
                return .success(try self.imageStorage.readImage(named: item.imageFileName, inClip: item.clipUrl))
            } catch ImageStorageError.notFound {
                return .failure(.notFound)
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func readThumbnailData(of item: ClipItem) -> Result<Data, ClipStorageError> {
        return self.queue.sync {
            do {
                return .success(try self.imageStorage.readImage(named: item.thumbnailFileName, inClip: item.clipUrl))
            } catch ImageStorageError.notFound {
                return .failure(.notFound)
            } catch {
                return .failure(.internalError)
            }
        }
    }

    // MARK: Update

    public func updateClips(having ids: [Clip.Identity], byHiding isHidden: Bool) -> Result<[Clip], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        var clips: [ClipObject] = []
        for id in ids.map({ $0.absoluteString }) {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: id) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        do {
            try realm.write {
                for clipObj in clips {
                    clipObj.isHidden = isHidden
                    clipObj.updatedAt = Date()
                }
            }
            return .success(clips.map { Clip.make(by: $0) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds.map({ $0.absoluteString }) {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        do {
            try realm.write {
                for clip in clips {
                    for tag in tags {
                        guard !clip.tags.contains(tag) else { continue }
                        clip.tags.append(tag)
                    }
                    clip.updatedAt = Date()
                }
            }
            return .success(clips.map { Clip.make(by: $0) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds.map({ $0.absoluteString }) {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        do {
            try realm.write {
                for clip in clips {
                    for tag in tags {
                        guard let index = clip.tags.firstIndex(of: tag) else { continue }
                        clip.tags.remove(at: index)
                    }
                    clip.updatedAt = Date()
                }
            }
            return .success(clips.map { Clip.make(by: $0) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId) else {
            return .failure(.notFound)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds.map({ $0.absoluteString }) {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clips.append(clip)
        }

        for clip in clips {
            guard !album.clips.contains(clip) else {
                return .failure(.duplicated)
            }
        }

        do {
            try realm.write {
                album.updatedAt = Date()

                for clip in clips {
                    if !album.clips.contains(clip) {
                        album.clips.append(clip)
                    }
                }
            }
            return .success(())
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId) else {
            return .failure(.notFound)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.absoluteString) else {
                return .failure(.notFound)
            }
            clips.append(clip)
        }

        for clip in clips {
            guard album.clips.contains(clip) else {
                return .failure(.notFound)
            }
        }

        let indices = clips.compactMap {
            album.clips.index(of: $0)
        }

        do {
            try realm.write {
                album.updatedAt = Date()
                album.clips.remove(atOffsets: IndexSet(indices))
            }
            return .success(())
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Album, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        if realm.objects(AlbumObject.self).filter("title = '\(title)'").first != nil {
            return .failure(.duplicated)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId) else {
            return .failure(.notFound)
        }

        do {
            try realm.write {
                album.updatedAt = Date()
                album.title = title
            }
            return .success(Album.make(by: album))
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Tag, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }

        do {
            try realm.write {
                tag.name = name
            }
            return .success(Tag.make(by: tag))
        } catch {
            return .failure(.internalError)
        }
    }

    // MARK: Delete

    public func deleteClips(having ids: [Clip.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        var clipObjects: [ClipObject] = []
        for clipId in ids.map({ $0.absoluteString }) {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clipObjects.append(clip)
        }
        let removeTargets = clipObjects.map { Clip.make(by: $0) }

        // NOTE: Delete only found objects.
        let clipItems = clipObjects
            .flatMap { $0.items }
            .map { $0.makeKey() }
            .compactMap { realm.object(ofType: ClipItemObject.self, forPrimaryKey: $0) }

        clipObjects
            .flatMap { $0.items }
            .forEach { clipItem in
                // swiftlint:disable:next force_unwrapping
                try? self.imageStorage.delete(fileName: clipItem.imageFileName, inClip: URL(string: clipItem.clipUrl)!)
                // swiftlint:disable:next force_unwrapping
                try? self.imageStorage.delete(fileName: clipItem.thumbnailFileName, inClip: URL(string: clipItem.clipUrl)!)
            }

        do {
            try realm.write {
                realm.delete(clipItems)
                realm.delete(clipObjects)
            }
            return .success(removeTargets)
        } catch {
            return .failure(.internalError)
        }
    }

    public func delete(_ clipItem: ClipItem) -> Result<ClipItem, ClipStorageError> {
        // TODO: Update clipItemIndex
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            let primaryKey = clipItem.asManagedObject().makeKey()
            guard let item = realm.object(ofType: ClipItemObject.self, forPrimaryKey: primaryKey) else {
                return .failure(.notFound)
            }
            let removeTarget = ClipItem.make(by: item)

            try? self.imageStorage.delete(fileName: clipItem.imageFileName, inClip: clipItem.clipUrl)
            try? self.imageStorage.delete(fileName: clipItem.thumbnailFileName, inClip: clipItem.clipUrl)

            do {
                try realm.write {
                    realm.delete(item)
                }
                return .success(removeTarget)
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func deleteAlbum(having id: Album.Identity) -> Result<Album, ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }
        let removeTarget = Album.make(by: album)

        do {
            try realm.write {
                realm.delete(album)
            }
            return .success(removeTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteTags(having ids: [Tag.Identity]) -> Result<[Tag], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else {
            return .failure(.internalError)
        }

        var tags: [TagObject] = []
        for id in ids {
            guard let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id) else {
                return .failure(.notFound)
            }
            tags.append(tag)
        }
        let deleteTarget = Array(tags.map({ Tag.make(by: $0) }))

        do {
            try realm.write {
                realm.delete(tags)
            }
            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }
}
