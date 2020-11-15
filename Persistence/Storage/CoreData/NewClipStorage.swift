//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable file_length force_cast force_unwrapping

import CoreData
import Domain

public class NewClipStorage {
    private let rootContext: NSManagedObjectContext
    private let context: NSManagedObjectContext

    public init(rootContext: NSManagedObjectContext,
                context: NSManagedObjectContext)
    {
        self.rootContext = rootContext
        self.context = context
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
        try self.rootContext.save()
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

    public func create(clip: Domain.Clip, allowTagCreation: Bool, overwrite: Bool) -> Result<Domain.Clip, ClipStorageError> {
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
                    let newTag = NSEntityDescription.insertNewObject(forEntityName: "Tag",
                                                                     into: self.context) as! Tag
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

            // Prepare new objects

            let newClip = NSEntityDescription.insertNewObject(forEntityName: "Clip",
                                                              into: self.context) as! Clip
            newClip.id = clip.id
            newClip.descriptionText = clip.description

            let items = NSMutableSet()
            clip.items.forEach { item in
                let newItem = NSEntityDescription.insertNewObject(forEntityName: "Item",
                                                                  into: self.context) as! Item
                newItem.id = item.id
                newItem.siteUrl = item.url
                newItem.clipId = clip.id
                newItem.index = Int64(item.clipIndex)
                newItem.imageFileName = item.imageFileName
                newItem.imageUrl = item.imageUrl
                newItem.imageHeight = item.imageSize.height
                newItem.imageWidth = item.imageSize.width
                newItem.createdDate = item.registeredDate
                newItem.updatedDate = item.updatedDate

                items.add(newItem)
            }
            newClip.items = items
            newClip.tags = NSSet(array: appendingTags)

            newClip.isHidden = clip.isHidden
            newClip.createdDate = clip.registeredDate
            newClip.updatedDate = clip.updatedDate

            // Delete

            oldClip?.items?
                .compactMap { $0 as? Item }
                .forEach { item in
                    self.context.delete(item)
                }

            return .success(newClip.map(to: Domain.Clip.self)!)
        } catch {
            return .failure(.internalError)
        }
    }

    public func create(tagWithName name: String) -> Result<Domain.Tag, ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            request.predicate = NSPredicate(format: "name == %@", name as CVarArg)
            guard try self.context.fetch(request).first == nil else {
                return .failure(.duplicated)
            }

            let tag = NSEntityDescription.insertNewObject(forEntityName: "Tag",
                                                          into: self.context) as! Tag
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
            let request = NSFetchRequest<Tag>(entityName: "Album")
            request.predicate = NSPredicate(format: "title == %@", title as CVarArg)
            guard try self.context.fetch(request).first == nil else {
                return .failure(.duplicated)
            }

            let album = NSEntityDescription.insertNewObject(forEntityName: "Album",
                                                            into: self.context) as! Album
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
            var clips: [Clip] = []
            for clipId in ids {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }

            clips.forEach { $0.isHidden = isHidden }

            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateClips(having clipIds: [Domain.Clip.Identity], byAddingTagsHaving tagIds: [Domain.Tag.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            var tags: [Tag] = []
            for tagId in tagIds {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
                guard let tag = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                tags.append(tag)
            }

            var clips: [Clip] = []
            for clipId in clipIds {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }

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
            var tags: [Tag] = []
            for tagId in tagIds {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
                guard let tag = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                tags.append(tag)
            }

            var clips: [Clip] = []
            for clipId in clipIds {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }

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
            var tags: [Tag] = []
            for tagId in tagIds {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
                guard let tag = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                tags.append(tag)
            }

            var clips: [Clip] = []
            for clipId in clipIds {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }

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
            let request = NSFetchRequest<Album>(entityName: "Album")
            request.predicate = NSPredicate(format: "id == %@", albumId as CVarArg)
            guard let album = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }

            var clips: [Clip] = []
            for clipId in clipIds {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }

            let albumClips = album.mutableOrderedSetValue(forKey: "clips")
            for clip in clips {
                guard !albumClips.contains(clip) else {
                    return .failure(.duplicated)
                }
            }

            album.updatedDate = Date()

            for clip in clips {
                if !albumClips.contains(clip) {
                    albumClips.add(clip)
                }
            }

            return .success(())
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byDeletingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        do {
            let request = NSFetchRequest<Album>(entityName: "Album")
            request.predicate = NSPredicate(format: "id == %@", albumId as CVarArg)
            guard let album = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }

            var clips: [Clip] = []
            for clipId in clipIds {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }

            let albumClips = album.mutableOrderedSetValue(forKey: "clips")
            for clip in clips {
                guard albumClips.contains(clip) else {
                    return .failure(.notFound)
                }
            }

            album.updatedDate = Date()
            clips.forEach { albumClips.remove($0) }

            return .success(())
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, titleTo title: String) -> Result<Domain.Album, ClipStorageError> {
        do {
            let alreadyExists: Bool = try {
                let request = NSFetchRequest<Tag>(entityName: "Album")
                request.predicate = NSPredicate(format: "title == %@", title as CVarArg)
                return try self.context.fetch(request).first != nil
            }()
            guard !alreadyExists else {
                return .failure(.duplicated)
            }

            let request = NSFetchRequest<Album>(entityName: "Album")
            request.predicate = NSPredicate(format: "id == %@", albumId as CVarArg)
            guard let album = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            guard let result = album.map(to: Domain.Album.self) else {
                return .failure(.internalError)
            }

            album.title = title
            album.updatedDate = Date()

            return .success(result)
        } catch {
            return .failure(.internalError)
        }
    }

    public func updateTag(having id: Domain.Tag.Identity, nameTo name: String) -> Result<Domain.Tag, ClipStorageError> {
        do {
            let request = NSFetchRequest<Tag>(entityName: "Tag")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            guard let tag = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            guard let result = tag.map(to: Domain.Tag.self) else {
                return .failure(.internalError)
            }

            tag.name = name

            return .success(result)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteClips(having ids: [Domain.Clip.Identity]) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            var clips: [Clip] = []
            for id in ids {
                let request = NSFetchRequest<Clip>(entityName: "Clip")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                guard let clip = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                clips.append(clip)
            }
            let deleteTarget = clips.compactMap { $0.map(to: Domain.Clip.self) }

            clips.forEach { self.context.delete($0) }

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItem, ClipStorageError> {
        do {
            let request = NSFetchRequest<Item>(entityName: "Item")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            guard let item = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }

            let removeTarget = item.map(to: Domain.ClipItem.self)!

            guard let clipItems = item.clip?.items?.compactMap({ $0 as? Item }) else {
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
            let request = NSFetchRequest<Album>(entityName: "Album")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            guard let album = try self.context.fetch(request).first else {
                return .failure(.notFound)
            }
            let deleteTarget = album.map(to: Domain.Album.self)!

            self.context.delete(album)

            return .success(deleteTarget)
        } catch {
            return .failure(.internalError)
        }
    }

    public func deleteTags(having ids: [Domain.Tag.Identity]) -> Result<[Domain.Tag], ClipStorageError> {
        do {
            var tags: [Tag] = []
            for id in ids {
                let request = NSFetchRequest<Tag>(entityName: "Tag")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                guard let tag = try self.context.fetch(request).first else {
                    return .failure(.notFound)
                }
                tags.append(tag)
            }
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
