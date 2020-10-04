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

    public func readClip(having url: URL) -> Result<Clip, ClipStorageError> {
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

    public func readAllClips(containsHiddenClips: Bool) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            if containsHiddenClips {
                return .success(realm.objects(ClipObject.self).map { Clip.make(by: $0) })
            } else {
                return .success(realm.objects(ClipObject.self).filter("isHidden == false").map { Clip.make(by: $0) })
            }
        }
    }

    public func readAllTags() -> Result<[String], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }
            return .success(realm.objects(TagObject.self).map { $0.name })
        }
    }

    public func readAllAlbums() -> Result<[Album], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }
            return .success(realm.objects(AlbumObject.self).map { Album.make(by: $0) })
        }
    }

    public func searchClips(byKeywords keywords: [String]) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
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

            return .success(results.map { Clip.make(by: $0) })
        }
    }

    public func searchClips(byTags tags: [String]) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            // Ignore not founded tags.
            let clips = tags
                .compactMap { realm.objects(TagObject.self).filter("name = '\($0)'").first }
                .flatMap { $0.clips }
                .map { Clip.make(by: $0) }

            let result = clips.reduce(into: [Clip]()) { result, clip in
                guard !result.contains(clip) else { return }
                result.append(clip)
            }

            return .success(result)
        }
    }

    // MARK: Update

    public func update(_ clip: Clip, byAddingTag tag: String) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let tagObj = realm.objects(TagObject.self).filter("name = '\(tag)'").first else {
                return .failure(.notFound)
            }

            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) else {
                return .failure(.notFound)
            }

            do {
                try realm.write {
                    if !clipObj.tags.contains(tagObj) {
                        clipObj.tags.append(tagObj)
                    }
                    clipObj.updatedAt = Date()
                }
                return .success(.make(by: clipObj))
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func update(_ clip: Clip, byDeletingTag tag: String) -> Result<Clip, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) else {
                return .failure(.notFound)
            }

            guard let index = clipObj.tags.firstIndex(where: { $0.name == tag }) else {
                return .failure(.notFound)
            }

            do {
                try realm.write {
                    clipObj.tags.remove(at: index)
                    clipObj.updatedAt = Date()
                }
                return .success(.make(by: clipObj))
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func update(_ clips: [Clip], byHiding isHidden: Bool) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            var clipObjs: [ClipObject] = []
            for clip in clips {
                guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) else {
                    return .failure(.notFound)
                }
                clipObjs.append(clipObj)
            }

            do {
                try realm.write {
                    for clipObj in clipObjs {
                        clipObj.isHidden = isHidden
                        clipObj.updatedAt = Date()
                    }
                }
                return .success(clipObjs.map { Clip.make(by: $0) })
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func update(_ clips: [Clip], byAddingTags tags: [String]) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            var tagObjs: [TagObject] = []
            for tag in tags {
                guard let tagObj = realm.objects(TagObject.self).filter("name = '\(tag)'").first else {
                    return .failure(.notFound)
                }
                tagObjs.append(tagObj)
            }

            var clipObjs: [ClipObject] = []
            for clip in clips {
                guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) else {
                    return .failure(.notFound)
                }
                clipObjs.append(clipObj)
            }

            do {
                try realm.write {
                    for clipObj in clipObjs {
                        for tagObj in tagObjs {
                            if !clipObj.tags.contains(tagObj) {
                                clipObj.tags.append(tagObj)
                            }
                        }
                        clipObj.updatedAt = Date()
                    }
                }
                return .success(clipObjs.map { Clip.make(by: $0) })
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func update(_ clips: [Clip], byAddingTags tags: [Tag]) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            let tagObjs = tags
                .compactMap { realm.object(ofType: TagObject.self, forPrimaryKey: $0.identity) }

            var clipObjs: [ClipObject] = []
            for clip in clips {
                guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) else {
                    return .failure(.notFound)
                }
                clipObjs.append(clipObj)
            }

            do {
                try realm.write {
                    for clipObj in clipObjs {
                        for tagObj in tagObjs {
                            if !clipObj.tags.contains(tagObj) {
                                clipObj.tags.append(tagObj)
                            }
                        }
                        clipObj.updatedAt = Date()
                    }
                }
                return .success(clipObjs.map { Clip.make(by: $0) })
            } catch {
                return .failure(.internalError)
            }
        }
    }

    public func update(_ album: Album, byAddingClipsHaving clipUrls: [URL]) -> Result<Void, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: album.id) else {
                return .failure(.notFound)
            }

            var clips: [ClipObject] = []
            for url in clipUrls {
                guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
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
    }

    public func update(_ album: Album, byDeletingClipsHaving clipUrls: [URL]) -> Result<Void, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: album.id) else {
                return .failure(.notFound)
            }

            var clips: [ClipObject] = []
            for url in clipUrls {
                guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: url.absoluteString) else {
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
    }

    public func update(_ album: Album, titleTo title: String) -> Result<Album, ClipStorageError> {
        self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            if realm.objects(AlbumObject.self).filter("title = '\(title)'").first != nil {
                return .failure(.duplicated)
            }

            guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: album.id) else {
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
    }

    // MARK: Delete

    public func delete(_ clips: [Clip]) -> Result<[Clip], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            var clipObjects: [ClipObject] = []
            for clip in clips {
                guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.url.absoluteString) else {
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

            clips
                .flatMap { $0.items }
                .forEach { clipItem in
                    try? self.imageStorage.delete(fileName: clipItem.imageFileName, inClip: clipItem.clipUrl)
                    try? self.imageStorage.delete(fileName: clipItem.thumbnailFileName, inClip: clipItem.clipUrl)
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

    public func delete(_ album: Album) -> Result<Album, ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: album.id) else {
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
    }

    public func delete(_ tags: [Tag]) -> Result<[Tag], ClipStorageError> {
        return self.queue.sync {
            guard let realm = try? Realm(configuration: self.configuration) else {
                return .failure(.internalError)
            }

            let filter = tags.reduce(into: "") { result, tag in
                let predicate = "name = '\(tag.name)'"
                if result.isEmpty {
                    result = predicate
                } else {
                    result += "OR \(predicate)"
                }
            }
            let tagObjs = realm.objects(TagObject.self).filter(filter)

            do {
                try realm.write {
                    realm.delete(tagObjs)
                }
                return .success(Array(tagObjs.map({ Tag.make(by: $0) })))
            } catch {
                return .failure(.internalError)
            }
        }
    }
}
