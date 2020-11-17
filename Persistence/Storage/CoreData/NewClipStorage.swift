//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable file_length force_cast force_unwrapping

import CoreData
import Domain

public class NewClipStorage {
    private let context: NSManagedObjectContext

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Methods

    private func fetchAlbum(for id: Domain.Album.Identity) throws -> Result<Album, ClipStorageError> {
        let request = NSFetchRequest<Album>(entityName: "Album")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let album = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(album)
    }

    private func fetchAlbum(for title: String) throws -> Result<Album, ClipStorageError> {
        let request = NSFetchRequest<Album>(entityName: "Album")
        request.predicate = NSPredicate(format: "title == %@", title as CVarArg)
        guard let album = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(album)
    }

    private func fetchTags(for ids: [Domain.Tag.Identity]) throws -> Result<[Tag], ClipStorageError> {
        var tags: [Tag] = []
        for tagId in ids {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            request.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
            guard let tag = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            tags.append(tag)
        }
        return .success(tags)
    }

    private func fetchTag(for id: Domain.Tag.Identity) throws -> Result<Tag, ClipStorageError> {
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let tag = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(tag)
    }

    private func fetchTag(for name: String) throws -> Result<Tag, ClipStorageError> {
        let request = NSFetchRequest<Tag>(entityName: "Tag")
        request.predicate = NSPredicate(format: "name == %@", name as CVarArg)
        guard let tag = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(tag)
    }

    private func fetchClips(for ids: [Domain.Clip.Identity]) throws -> Result<[Clip], ClipStorageError> {
        var clips: [Clip] = []
        for clipId in ids {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
            guard let clip = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            clips.append(clip)
        }
        return .success(clips)
    }

    private func fetchClipItem(for id: Domain.ClipItem.Identity) throws -> Result<Item, ClipStorageError> {
        let request = NSFetchRequest<Item>(entityName: "ClipItem")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let item = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(item)
    }
}

extension NewClipStorage: ClipStorageProtocol {
    public var isInTransaction: Bool {
        return self.context.hasChanges
    }

    public func beginTransaction() throws {
        // NOP
    }

    public func commitTransaction() throws {
        try self.context.save()
    }

    public func cancelTransactionIfNeeded() throws {
        self.context.rollback()
    }

    public func readAllClips() -> Result<[Domain.Clip], ClipStorageError> {
        do {
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            let clips = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Clip.self) }
            return .success(clips)
        } catch {
            return .failure(.internalError)
        }
    }

    public func readAllTags() -> Result<[Domain.Tag], ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            let tags = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Tag.self) }
            return .success(tags)
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(clip: Domain.Clip, allowTagCreation: Bool, overwrite: Bool) -> Result<(new: Domain.Clip, old: Domain.Clip?), ClipStorageError> {
        do {
            // Check parameters

            var appendingTags: [Tag] = []
            for tag in clip.tags {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                if let tag = try self.context.fetch(request).first {
                    appendingTags.append(tag)
                } else {
                    guard allowTagCreation else {
                        return .failure(.invalidParameter)
                    }
                    let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: self.context) as! Tag
                    newTag.id = tag.id
                    newTag.name = tag.name
                    newTag.isHidden = false
                    appendingTags.append(newTag)
                }
            }

            // Check duplication

            var oldClip: Clip?
            let request = NSFetchRequest<Clip>(entityName: "Clip")
            request.predicate = NSPredicate(format: "id == %@", clip.id as CVarArg)
            if let duplicatedClip = try self.context.fetch(request).first {
                if overwrite {
                    oldClip = duplicatedClip
                } else {
                    return .failure(.duplicated)
                }
            }
            let domainOldClip = oldClip?.map(to: Domain.Clip.self)

            // Prepare new objects

            let newClip = NSEntityDescription.insertNewObject(forEntityName: "Clip", into: self.context) as! Clip
            newClip.id = clip.id
            newClip.descriptionText = clip.description

            let items = NSMutableSet()
            clip.items.forEach { item in
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "ClipItem", into: self.context) as! Item
                newItem.id = item.id
                newItem.siteUrl = item.url
                newItem.clipId = clip.id
                newItem.index = Int64(item.clipIndex)
                newItem.imageId = item.imageId
                newItem.imageFileName = item.imageFileName
                newItem.imageUrl = item.imageUrl
                newItem.imageHeight = item.imageSize.height
                newItem.imageWidth = item.imageSize.width
                newItem.createdDate = item.registeredDate
                newItem.updatedDate = item.updatedDate

                items.add(newItem)
            }
            newClip.clipItems = items
            newClip.tags = NSSet(array: appendingTags)

            newClip.isHidden = clip.isHidden
            newClip.createdDate = clip.registeredDate
            newClip.updatedDate = clip.updatedDate

            // Delete

            oldClip?.clipItems?
                .compactMap { $0 as? Item }
                .forEach { item in
                    self.context.delete(item)
                }

            return .success((new: newClip.map(to: Domain.Clip.self)!, old: domainOldClip))
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(tagWithName name: String) -> Result<Domain.Tag, ClipStorageError> {
        do {
            guard case .failure = try self.fetchTag(for: name) else { return .failure(.duplicated) }

            let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag", into: self.context) as! Tag
            tag.id = UUID()
            tag.name = name
            tag.isHidden = false

            return .success(tag.map(to: Domain.Tag.self)!)
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(albumWithTitle title: String) -> Result<Domain.Album, ClipStorageError> {
        do {
            guard case .failure = try self.fetchAlbum(for: title) else { return .failure(.duplicated) }

            let album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: self.context) as! Album
            album.id = UUID()
            album.title = title
            album.createdDate = Date()
            album.updatedDate = Date()
            album.isHidden = false

            return .success(album.map(to: Domain.Album.self)!)
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having ids: [Domain.Clip.Identity], byHiding isHidden: Bool) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            guard case let .success(clips) = try self.fetchClips(for: ids) else { return .failure(.notFound) }

            clips.forEach { $0.isHidden = isHidden }

            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byAddingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            guard case let .success(tags) = try self.fetchTags(for: tagIds) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            for clip in clips {
                var updated = false

                for tag in tags {
                    let tags = clip.mutableSetValue(forKey: "tags")
                    guard !tags.contains(tag) else { continue }
                    tags.add(tag)
                    updated = true
                }

                if updated {
                    clip.updatedDate = Date()
                }
            }

            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byDeletingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            guard case let .success(tags) = try self.fetchTags(for: tagIds) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            for clip in clips {
                var updated = false

                for tag in tags {
                    let tags = clip.mutableSetValue(forKey: "tags")
                    guard tags.contains(tag) else { continue }
                    tags.remove(tag)
                    updated = true
                }

                if updated {
                    clip.updatedDate = Date()
                }
            }
            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byReplacingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            guard case let .success(tags) = try self.fetchTags(for: tagIds) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            for clip in clips {
                let clipTags = clip.mutableSetValue(forKey: "tags")
                clipTags.removeAllObjects()
                tags.forEach { clipTags.add($0) }
                clip.updatedDate = Date()
            }

            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byAddingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            let albumItems = album.mutableSetValue(forKey: "items")

            let alreadyAdded = clips
                .allSatisfy { clip in
                    albumItems
                        .compactMap { $0 as? AlbumItem }
                        .contains { $0.clip == clip }
                }
            guard !alreadyAdded else { return .failure(.duplicated) }

            let maxIndex = albumItems
                .compactMap { $0 as? AlbumItem }
                .max(by: { $0.index < $1.index })?
                .index ?? 0
            for (index, clip) in clips.enumerated() {
                let albumItem = NSEntityDescription.insertNewObject(forEntityName: "AlbumItem", into: self.context) as! AlbumItem
                albumItem.id = UUID()
                albumItem.index = maxIndex + Int64(index + 1)
                albumItem.clip = clip
                albumItems.add(albumItem)
            }
            album.updatedDate = Date()

            return .success(())
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byDeletingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            let albumItems = album.mutableSetValue(forKey: "items")

            let alreadyAdded = clips
                .allSatisfy { clip in
                    albumItems
                        .compactMap { $0 as? AlbumItem }
                        .contains { $0.clip == clip }
                }
            guard alreadyAdded else { return .failure(.notFound) }

            var currentIndex: Int64 = 1
            albumItems
                .compactMap { $0 as? AlbumItem }
                .sorted(by: { $0.index < $1.index })
                .forEach { albumItem in
                    guard let clipId = albumItem.clip?.id else {
                        self.context.delete(albumItem)
                        return
                    }
                    if clipIds.contains(clipId) {
                        self.context.delete(albumItem)
                    } else {
                        albumItem.index = currentIndex
                        currentIndex += 1
                    }
                }
            album.updatedDate = Date()

            return .success(())
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, titleTo title: String) -> Result<Domain.Album, ClipStorageError> {
        do {
            guard case .failure = try self.fetchAlbum(for: title) else { return .failure(.duplicated) }
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else { return .failure(.notFound) }
            guard let result = album.map(to: Domain.Album.self) else { return .failure(.internalError) }

            album.title = title
            album.updatedDate = Date()

            return .success(result)
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateTag(having id: Domain.Tag.Identity, nameTo name: String) -> Result<Domain.Tag, ClipStorageError> {
        do {
            guard case let .success(tag) = try self.fetchTag(for: id) else { return .failure(.notFound) }
            guard let result = tag.map(to: Domain.Tag.self) else { return .failure(.internalError) }

            tag.name = name

            return .success(result)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteClips(having ids: [Domain.Clip.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            guard case let .success(clips) = try self.fetchClips(for: ids) else { return .failure(.notFound) }
            let deleteTarget = clips.compactMap { $0.map(to: Domain.Clip.self) }

            clips.forEach { self.context.delete($0) }

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItem, ClipStorageError> {
        do {
            guard case let .success(item) = try self.fetchClipItem(for: id) else { return .failure(.notFound) }
            let removeTarget = item.map(to: Domain.ClipItem.self)!

            guard let clipItems = item.clip?.clipItems?.compactMap({ $0 as? Item }) else {
                self.context.delete(item)
                return .success(removeTarget)
            }

            var index: Int64 = 0
            for clipItem in clipItems {
                if clipItem.id == id {
                    self.context.delete(item)
                    continue
                }
                clipItem.index = index
                index += 1
            }

            return .success(removeTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteAlbum(having id: Domain.Album.Identity) -> Result<Domain.Album, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: id) else { return .failure(.notFound) }
            let deleteTarget = album.map(to: Domain.Album.self)!

            self.context.delete(album)

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteTags(having ids: [Domain.Tag.Identity]) -> Result<[Domain.Tag], ClipStorageError> {
        do {
            guard case let .success(tags) = try self.fetchTags(for: ids) else { return .failure(.notFound) }
            let deleteTarget = tags.compactMap { $0.map(to: Domain.Tag.self) }

            tags.forEach { self.context.delete($0) }

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteAll() -> Result<Void, ClipStorageError> {
        return .failure(.internalError)
    }
}
