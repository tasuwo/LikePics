//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift

// swiftlint:disable contains_over_filter_is_empty first_where

public class ClipStorage {
    public enum StorageConfiguration {
        static let realmFileName = "clips.realm"

        public static func makeConfiguration() -> Realm.Configuration {
            var configuration = Realm.Configuration(
                schemaVersion: 9,
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

    let configuration: Realm.Configuration

    private let logger: TBoxLoggable
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ClipStorage")

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

extension ClipStorage: ClipStorageProtocol {
    // MARK: - ClipStorageProtocol

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

    public func cancelTransaction() {
        defer { self.realm = nil }
        guard let realm = self.realm, realm.isInWriteTransaction else { return }
        realm.cancelWrite()
    }

    public func create(clip: Clip, forced: Bool) -> Result<Clip.Identity, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        // Check parameters

        var appendingTags: [TagObject] = []
        for tag in clip.tags {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tag.identity) else {
                return .failure(.invalidParameter)
            }
            appendingTags.append(tagObj)
        }

        // Check duplication

        var duplicatedClip: ClipObject?
        if let clipUrl = clip.url, let clipObject = realm.objects(ClipObject.self).filter("url = '\(clipUrl)'").first {
            if forced {
                duplicatedClip = clipObject
            } else {
                return .failure(.duplicated)
            }
        }

        // Prepare new objects

        let targetClipId = duplicatedClip?.id ?? clip.id

        let newClip = ClipObject()
        newClip.id = targetClipId
        newClip.url = clip.url?.absoluteString
        newClip.descriptionText = clip.description

        clip.items.forEach { item in
            let newClipItem = ClipItemObject()

            newClipItem.id = item.id
            newClipItem.clipId = targetClipId
            newClipItem.clipIndex = item.clipIndex
            newClipItem.imageFileName = item.imageFileName
            newClipItem.imageUrl = item.imageUrl?.absoluteString
            newClipItem.imageHeight = item.imageSize.height
            newClipItem.imageWidth = item.imageSize.width
            newClipItem.registeredAt = item.registeredDate
            newClipItem.updatedAt = item.updatedDate

            newClip.items.append(newClipItem)
        }

        appendingTags.forEach { newClip.tags.append($0) }

        newClip.isHidden = clip.isHidden
        if let oldClip = duplicatedClip {
            // TODO: Share時のタグの追加をサポートし、このタグの引継ぎ処理を削除する
            oldClip.tags.forEach { newClip.tags.append($0) }
            newClip.registeredAt = oldClip.registeredAt
        } else {
            newClip.registeredAt = clip.registeredDate
        }
        newClip.updatedAt = clip.updatedDate

        // Delete

        let updatePolicy: Realm.UpdatePolicy = forced ? .modified : .error
        duplicatedClip?.items.forEach { item in
            realm.delete(item)
        }
        realm.add(newClip, update: updatePolicy)

        return .success(targetClipId)
    }

    public func create(tagWithName name: String) -> Result<Tag, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if !realm.objects(TagObject.self).filter("name = '\(name)'").isEmpty {
            return .failure(.duplicated)
        }

        let obj = TagObject()
        obj.id = UUID().uuidString
        obj.name = name

        realm.add(obj)
        return .success(.make(by: obj))
    }

    public func create(albumWithTitle title: String) -> Result<Album, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if !realm.objects(AlbumObject.self).filter("title = '\(title)'").isEmpty {
            return .failure(.duplicated)
        }

        let obj = AlbumObject()
        obj.id = UUID().uuidString
        obj.title = title
        obj.registeredAt = Date()
        obj.updatedAt = Date()

        realm.add(obj)
        return .success(Album.make(by: obj))
    }

    // MARK: Update

    public func updateClips(having ids: [Clip.Identity], byHiding isHidden: Bool) -> Result<[Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var clips: [ClipObject] = []
        for id in ids {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: id) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        for clipObj in clips {
            clipObj.isHidden = isHidden
            clipObj.updatedAt = Date()
        }
        return .success(clips.map { Clip.make(by: $0) })
    }

    public func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        for clip in clips {
            for tag in tags {
                guard !clip.tags.contains(tag) else { continue }
                clip.tags.append(tag)
            }
            clip.updatedAt = Date()
        }
        return .success(clips.map { Clip.make(by: $0) })
    }

    public func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        for clip in clips {
            for tag in tags {
                guard let index = clip.tags.firstIndex(of: tag) else { continue }
                clip.tags.remove(at: index)
            }
            clip.updatedAt = Date()
        }
        return .success(clips.map { Clip.make(by: $0) })
    }

    public func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        for clip in clips {
            clip.tags.removeAll()
            tags.forEach { clip.tags.append($0) }
            clip.updatedAt = Date()
        }
        return .success(clips.map { Clip.make(by: $0) })
    }

    public func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId) else {
            return .failure(.notFound)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
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

        album.updatedAt = Date()

        for clip in clips {
            if !album.clips.contains(clip) {
                album.clips.append(clip)
            }
        }
        return .success(())
    }

    public func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId) else {
            return .failure(.notFound)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
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

        album.updatedAt = Date()
        album.clips.remove(atOffsets: IndexSet(indices))
        return .success(())
    }

    public func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Album, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if realm.objects(AlbumObject.self).filter("title = '\(title)'").first != nil {
            return .failure(.duplicated)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId) else {
            return .failure(.notFound)
        }

        album.updatedAt = Date()
        album.title = title
        return .success(Album.make(by: album))
    }

    public func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Tag, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }

        tag.name = name
        return .success(Tag.make(by: tag))
    }

    // MARK: Delete

    public func deleteClips(having ids: [Clip.Identity]) -> Result<[Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var clipObjects: [ClipObject] = []
        for clipId in ids {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId) else {
                return .failure(.notFound)
            }
            clipObjects.append(clip)
        }
        let removeTargets = clipObjects.map { Clip.make(by: $0) }

        // NOTE: Delete only found objects.
        let clipItems = clipObjects
            .flatMap { $0.items }
            .compactMap { realm.object(ofType: ClipItemObject.self, forPrimaryKey: $0.id) }

        realm.delete(clipItems)
        realm.delete(clipObjects)

        return .success(removeTargets)
    }

    public func deleteClipItem(having id: ClipItem.Identity) -> Result<ClipItem, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let item = realm.object(ofType: ClipItemObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }
        let removeTarget = ClipItem.make(by: item)

        guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: item.clipId) else {
            return .failure(.notFound)
        }

        realm.delete(item)
        clip.items
            .sorted(by: { $0.clipIndex < $1.clipIndex })
            .enumerated()
            .forEach { $0.element.clipIndex = $0.offset }

        return .success(removeTarget)
    }

    public func deleteAlbum(having id: Album.Identity) -> Result<Album, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: id) else {
            return .failure(.notFound)
        }
        let removeTarget = Album.make(by: album)

        realm.delete(album)
        return .success(removeTarget)
    }

    public func deleteTags(having ids: [Tag.Identity]) -> Result<[Tag], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for id in ids {
            guard let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id) else {
                return .failure(.notFound)
            }
            tags.append(tag)
        }

        let deleteTarget = Array(tags.map({ Tag.make(by: $0) }))

        realm.delete(tags)
        return .success(deleteTarget)
    }
}
