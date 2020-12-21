//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import RealmSwift

// swiftlint:disable contains_over_filter_is_empty first_where

public class ClipStorage {
    public struct Configuration {
        let realmConfiguration: Realm.Configuration
    }

    let configuration: Realm.Configuration
    private let logger: TBoxLoggable
    private var realm: Realm?

    // MARK: - Lifecycle

    public init(config: ClipStorage.Configuration, logger: TBoxLoggable) throws {
        self.configuration = config.realmConfiguration
        self.logger = logger
    }
}

extension ClipStorage: ClipStorageProtocol {
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

    public func readAllClips() -> Result<[Domain.Clip], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let clips = realm.objects(ClipObject.self)
            .map { Domain.Clip.make(by: $0) }
        return .success(Array(clips))
    }

    public func readAllTags() -> Result<[Domain.Tag], ClipStorageError> {
        guard let realm = try? Realm(configuration: self.configuration) else { return .failure(.internalError) }
        let tags = realm.objects(TagObject.self)
            .map { Domain.Tag.make(by: $0) }
        return .success(Array(tags))
    }

    // MARK: Create

    public func create(clip: Domain.Clip, overwrite: Bool) -> Result<(new: Domain.Clip, old: Domain.Clip?), ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        // Check parameters

        var appendingTags: [TagObject] = []
        for tag in clip.tags {
            // IDが同一の既存のタグがあれば、そちらを利用する
            if let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tag.identity.uuidString) {
                appendingTags.append(tagObj)
                continue
            }

            // 名前が同一の既存のタグがあれば、そちらを利用する
            if let tagObj = realm.objects(TagObject.self).filter("name = '\(tag.name)'").first {
                appendingTags.append(tagObj)
                continue
            }

            // ID or 名前が同一のタグが存在しなければ、タグを新たに作成する
            let newTag = TagObject()
            newTag.id = tag.id.uuidString
            newTag.name = tag.name
            appendingTags.append(newTag)
        }

        // Check duplication

        var oldClip: ClipObject?
        if let duplicatedClip = realm.object(ofType: ClipObject.self, forPrimaryKey: clip.identity.uuidString) {
            if overwrite {
                oldClip = duplicatedClip
            } else {
                return .failure(.duplicated)
            }
        }
        let domainOldClip: Domain.Clip? = {
            guard let oldClip = oldClip else { return nil }
            return Domain.Clip.make(by: oldClip)
        }()

        // Prepare new objects

        let newClip = ClipObject()
        newClip.id = clip.id.uuidString
        newClip.descriptionText = clip.description

        clip.items.forEach { item in
            let newClipItem = ClipItemObject()

            newClipItem.id = item.id.uuidString
            newClipItem.url = item.url?.absoluteString
            newClipItem.clipId = clip.id.uuidString
            newClipItem.clipIndex = item.clipIndex
            newClipItem.imageId = item.imageId.uuidString
            newClipItem.imageFileName = item.imageFileName
            newClipItem.imageUrl = item.imageUrl?.absoluteString
            newClipItem.imageHeight = item.imageSize.height
            newClipItem.imageWidth = item.imageSize.width
            newClipItem.imageDataSize = item.imageDataSize
            newClipItem.registeredAt = item.registeredDate
            newClipItem.updatedAt = item.updatedDate

            newClip.items.append(newClipItem)
        }

        appendingTags.forEach { newClip.tags.append($0) }

        newClip.dataSize = clip.dataSize
        newClip.isHidden = clip.isHidden
        newClip.registeredAt = clip.registeredDate
        newClip.updatedAt = clip.updatedDate

        // Delete

        oldClip?.items.forEach { item in
            realm.delete(item)
        }

        // Add

        let updatePolicy: Realm.UpdatePolicy = overwrite ? .modified : .error
        realm.add(newClip, update: updatePolicy)

        return .success((new: Domain.Clip.make(by: newClip), old: domainOldClip))
    }

    public func create(tagWithName name: String) -> Result<Domain.Tag, ClipStorageError> {
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

    public func create(_ tag: Domain.Tag) -> Result<Domain.Tag, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if realm.object(ofType: TagObject.self, forPrimaryKey: tag.id.uuidString) != nil {
            return .failure(.duplicated)
        }

        if realm.objects(TagObject.self).filter("name = '\(tag.name)'").isEmpty == false {
            return .failure(.duplicated)
        }

        let obj = TagObject()
        obj.id = tag.id.uuidString
        obj.name = tag.name

        realm.add(obj)
        return .success(.make(by: obj))
    }

    public func create(albumWithTitle title: String) -> Result<Domain.Album, ClipStorageError> {
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
        return .success(Domain.Album.make(by: obj))
    }

    // MARK: Update

    public func updateClips(having ids: [Domain.Clip.Identity], byHiding isHidden: Bool) -> Result<[Domain.Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var clips: [ClipObject] = []
        for id in ids {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: id.uuidString) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        for clipObj in clips {
            clipObj.isHidden = isHidden
            clipObj.updatedAt = Date()
        }
        return .success(clips.map { Domain.Clip.make(by: $0) })
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byAddingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId.uuidString) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.uuidString) else {
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
        return .success(clips.map { Domain.Clip.make(by: $0) })
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byDeletingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId.uuidString) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.uuidString) else {
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
        return .success(clips.map { Domain.Clip.make(by: $0) })
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byReplacingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for tagId in tagIds {
            guard let tagObj = realm.object(ofType: TagObject.self, forPrimaryKey: tagId.uuidString) else {
                return .failure(.notFound)
            }
            tags.append(tagObj)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clipObj = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.uuidString) else {
                return .failure(.notFound)
            }
            clips.append(clipObj)
        }

        for clip in clips {
            clip.tags.removeAll()
            tags.forEach { clip.tags.append($0) }
            clip.updatedAt = Date()
        }
        return .success(clips.map { Domain.Clip.make(by: $0) })
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byAddingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId.uuidString) else {
            return .failure(.notFound)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.uuidString) else {
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

    public func updateAlbum(having albumId: Domain.Album.Identity, byDeletingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId.uuidString) else {
            return .failure(.notFound)
        }

        var clips: [ClipObject] = []
        for clipId in clipIds {
            guard let clip = realm.object(ofType: ClipObject.self, forPrimaryKey: clipId.uuidString) else {
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

    public func updateAlbum(having albumId: Domain.Album.Identity, titleTo title: String) -> Result<Domain.Album, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        if realm.objects(AlbumObject.self).filter("title = '\(title)'").first != nil {
            return .failure(.duplicated)
        }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: albumId.uuidString) else {
            return .failure(.notFound)
        }

        album.updatedAt = Date()
        album.title = title
        return .success(Domain.Album.make(by: album))
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byReorderingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        return .failure(.internalError)
    }

    public func updateTag(having id: Domain.Tag.Identity, nameTo name: String) -> Result<Domain.Tag, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id.uuidString) else {
            return .failure(.notFound)
        }

        tag.name = name
        return .success(Domain.Tag.make(by: tag))
    }

    // MARK: Delete

    public func deleteClips(having ids: [Domain.Clip.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
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

    public func deleteClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItem, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let item = realm.object(ofType: ClipItemObject.self, forPrimaryKey: id.uuidString) else {
            return .failure(.notFound)
        }
        let removeTarget = Domain.ClipItem.make(by: item)

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

    public func deleteAlbum(having id: Domain.Album.Identity) -> Result<Domain.Album, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        guard let album = realm.object(ofType: AlbumObject.self, forPrimaryKey: id.uuidString) else {
            return .failure(.notFound)
        }
        let removeTarget = Domain.Album.make(by: album)

        realm.delete(album)
        return .success(removeTarget)
    }

    public func deleteTags(having ids: [Domain.Tag.Identity]) -> Result<[Domain.Tag], ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }

        var tags: [TagObject] = []
        for id in ids {
            guard let tag = realm.object(ofType: TagObject.self, forPrimaryKey: id.uuidString) else {
                return .failure(.notFound)
            }
            tags.append(tag)
        }

        let deleteTarget = Array(tags.map({ Domain.Tag.make(by: $0) }))

        realm.delete(tags)
        return .success(deleteTarget)
    }

    public func deleteAllTags() -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }
        realm.delete(realm.objects(TagObject.self))
        return .success(())
    }

    public func deleteAll() -> Result<Void, ClipStorageError> {
        guard let realm = self.realm, realm.isInWriteTransaction else { return .failure(.internalError) }
        realm.deleteAll()
        return .success(())
    }
}
