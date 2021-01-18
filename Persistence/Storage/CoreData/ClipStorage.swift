//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable force_unwrapping

import Common
import CoreData
import Domain

public class ClipStorage {
    public var context: NSManagedObjectContext {
        willSet {
            self.context.perform { [weak self] in
                if self?.context.hasChanges == true {
                    self?.context.rollback()
                }
            }
        }
    }

    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    public init(context: NSManagedObjectContext, logger: TBoxLoggable = RootLogger.shared) {
        self.context = context
        self.logger = logger
    }

    // MARK: - Methods

    private func fetchClip(for id: Domain.Clip.Identity) throws -> Result<Clip, ClipStorageError> {
        let request: NSFetchRequest<Clip> = Clip.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let clip = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(clip)
    }

    private func fetchAlbum(for id: Domain.Album.Identity) throws -> Result<Album, ClipStorageError> {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let album = try self.context.fetch(request).first else {
            self.logger.write(ConsoleLog(level: .error, message: "Album not found (id=\(id.uuidString))"))
            return .failure(.notFound)
        }
        return .success(album)
    }

    private func fetchAlbum(for title: String) throws -> Result<Album, ClipStorageError> {
        let request: NSFetchRequest<Album> = Album.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title as CVarArg)
        guard let album = try self.context.fetch(request).first else {
            self.logger.write(ConsoleLog(level: .error, message: "Album not found (title=\(title))"))
            return .failure(.notFound)
        }
        return .success(album)
    }

    private func fetchTags(for ids: [Domain.Tag.Identity]) throws -> Result<[Tag], ClipStorageError> {
        var tags: [Tag] = []
        for tagId in ids {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
            guard let tag = try self.context.fetch(request).first else {
                self.logger.write(ConsoleLog(level: .error, message: "Tag not found (id=\(tagId.uuidString))"))
                return .failure(.notFound)
            }
            tags.append(tag)
        }
        return .success(tags)
    }

    private func fetchTag(for id: Domain.Tag.Identity) throws -> Result<Tag, ClipStorageError> {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let tag = try self.context.fetch(request).first else {
            return .failure(.notFound)
        }
        return .success(tag)
    }

    private func fetchTag(for name: String) throws -> Result<Tag, ClipStorageError> {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name as CVarArg)
        guard let tag = try self.context.fetch(request).first else {
            self.logger.write(ConsoleLog(level: .error, message: "Tag not found (name=\(name))"))
            return .failure(.notFound)
        }
        return .success(tag)
    }

    private func fetchClips(for ids: [Domain.Clip.Identity]) throws -> Result<[Clip], ClipStorageError> {
        var clips: [Clip] = []
        for clipId in ids {
            let request: NSFetchRequest<Clip> = Clip.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", clipId as CVarArg)
            guard let clip = try self.context.fetch(request).first else {
                self.logger.write(ConsoleLog(level: .error, message: "Clip not found (id=\(clipId.uuidString))"))
                return .failure(.notFound)
            }
            clips.append(clip)
        }
        return .success(clips)
    }

    private func fetchClipItems(for ids: [Domain.ClipItem.Identity]) throws -> Result<[Item], ClipStorageError> {
        var items: [Item] = []
        for clipItemId in ids {
            let request: NSFetchRequest<Item> = Item.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", clipItemId as CVarArg)
            guard let item = try self.context.fetch(request).first else {
                self.logger.write(ConsoleLog(level: .error, message: "ClipItem not found (id=\(clipItemId.uuidString))"))
                return .failure(.notFound)
            }
            items.append(item)
        }
        return .success(items)
    }

    private func fetchClipItem(for id: Domain.ClipItem.Identity) throws -> Result<Item, ClipStorageError> {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let item = try self.context.fetch(request).first else {
            self.logger.write(ConsoleLog(level: .error, message: "ClipItem not found (id=\(id.uuidString))"))
            return .failure(.notFound)
        }
        return .success(item)
    }
}

extension ClipStorage: ClipStorageProtocol {
    public var isInTransaction: Bool {
        return self.context.hasChanges
    }

    public func beginTransaction() throws {
        // FIXME: タイミングによって `unrecognized selector sent to instance` でクラッシュすることがあるため、コメントアウト
        // self.context.reset()
    }

    public func commitTransaction() throws {
        try self.context.save()
    }

    public func cancelTransactionIfNeeded() throws {
        self.context.rollback()
    }

    public func readAllClips() -> Result<[Domain.Clip], ClipStorageError> {
        do {
            let request: NSFetchRequest<Clip> = Clip.fetchRequest()
            let clips = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Clip.self) }
            return .success(clips)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read clips. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func readAllTags() -> Result<[Domain.Tag], ClipStorageError> {
        do {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            let tags = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Tag.self) }
            return .success(tags)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read tags. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func readTags(forClipHaving clipId: Domain.Clip.Identity) -> Result<[Domain.Tag], ClipStorageError> {
        do {
            let request: NSFetchRequest<Tag> = Tag.fetchRequest()
            request.predicate = NSPredicate(format: "SUBQUERY(clips, $clip, $clip.id == %@).@count > 0", clipId as CVarArg)
            let tags = try self.context.fetch(request)
                .compactMap { $0.map(to: Domain.Tag.self) }
            return .success(tags)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read tags. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func readClipItems(having itemIds: [Domain.ClipItem.Identity]) -> Result<[Domain.ClipItem], ClipStorageError> {
        do {
            guard case let .success(items) = try self.fetchClipItems(for: itemIds) else { return .failure(.notFound) }
            return .success(items.compactMap({ $0.map(to: Domain.ClipItem.self) }))
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read clip items. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func readAlbumIds(containsClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<[Domain.Album.Identity], ClipStorageError> {
        do {
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            let albumIds = clips
                .map { $0.albumItem }
                .compactMap { $0?.allObjects }
                .flatMap { $0 }
                .compactMap { $0 as? Persistence.AlbumItem }
                .compactMap { $0.album?.id }

            return .success(Array(Set(albumIds)))
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read clips. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func create(clip: ClipRecipe) -> Result<Domain.Clip, ClipStorageError> {
        do {
            // Check parameters

            var appendingTags: [Tag] = []
            for tagId in clip.tagIds {
                // IDが同一の既存のタグがあれば、そちらを利用する
                let requestById: NSFetchRequest<Tag> = Tag.fetchRequest()
                requestById.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
                if let tag = try self.context.fetch(requestById).first {
                    appendingTags.append(tag)
                    continue
                }

                // IDが同一のタグが存在しなければ、スキップする
                self.logger.write(ConsoleLog(level: .error, message: """
                クリップ作成のためのタグ(ID: \(tagId))が見つかりませんでした。無視してクリップを作成します
                """))
            }

            // Prepare new objects

            let newClip = Clip(context: self.context)
            newClip.id = clip.id
            newClip.descriptionText = clip.description

            let items = NSMutableSet()
            clip.items.forEach { item in
                let newItem = Item(context: self.context)
                newItem.id = item.id
                newItem.siteUrl = item.url
                newItem.clipId = clip.id
                newItem.index = Int64(item.clipIndex)
                newItem.imageId = item.imageId
                newItem.imageFileName = item.imageFileName
                newItem.imageUrl = item.imageUrl
                newItem.imageHeight = item.imageSize.height
                newItem.imageWidth = item.imageSize.width
                newItem.imageSize = Int64(item.imageDataSize)
                newItem.createdDate = item.registeredDate
                newItem.updatedDate = item.updatedDate

                items.add(newItem)
            }
            newClip.clipItems = items
            newClip.tags = NSSet(array: appendingTags)

            newClip.imagesSize = Int64(clip.dataSize)
            newClip.isHidden = clip.isHidden
            newClip.createdDate = clip.registeredDate
            newClip.updatedDate = clip.updatedDate

            return .success(newClip.map(to: Domain.Clip.self)!)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to create clip. (error=\(error.localizedDescription))"))
            return .failure(.internalError)
        }
    }

    public func create(tagWithName name: String) -> Result<Domain.Tag, ClipStorageError> {
        do {
            guard case .failure = try self.fetchTag(for: name) else {
                self.logger.write(ConsoleLog(level: .error, message: "Failed to create tag. Duplicated."))
                return .failure(.duplicated)
            }

            let tag = Tag(context: self.context)
            tag.id = UUID()
            tag.name = name
            tag.isHidden = false

            return .success(tag.map(to: Domain.Tag.self)!)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to create tag. (error=\(error.localizedDescription))"))
            return .failure(.internalError)
        }
    }

    public func create(_ tag: Domain.Tag) -> Result<Domain.Tag, ClipStorageError> {
        do {
            guard case .failure = try self.fetchTag(for: tag.id) else {
                self.logger.write(ConsoleLog(level: .error, message: "Failed to create tag. Duplicated."))
                return .failure(.duplicated)
            }

            guard case .failure = try self.fetchTag(for: tag.name) else {
                self.logger.write(ConsoleLog(level: .error, message: "Failed to create tag. Duplicated."))
                return .failure(.duplicated)
            }

            let newTag = Tag(context: self.context)
            newTag.id = tag.id
            newTag.name = tag.name
            newTag.isHidden = false

            return .success(tag)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to create tag. (error=\(error.localizedDescription))"))
            return .failure(.internalError)
        }
    }

    public func create(albumWithTitle title: String) -> Result<Domain.Album, ClipStorageError> {
        do {
            guard case .failure = try self.fetchAlbum(for: title) else {
                self.logger.write(ConsoleLog(level: .error, message: "Failed to create album. Duplicated."))
                return .failure(.duplicated)
            }
            let request: NSFetchRequest<Album> = Album.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.index, ascending: true)]
            let albums = try self.context.fetch(request)

            let album = Album(context: self.context)
            album.id = UUID()
            album.title = title
            album.index = 1
            album.createdDate = Date()
            album.updatedDate = Date()
            album.isHidden = false

            var currentIndex: Int64 = 2
            albums.forEach {
                $0.index = currentIndex
                currentIndex += 1
            }

            return .success(album.map(to: Domain.Album.self)!)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to create album. (error=\(error.localizedDescription))"))
            return .failure(.internalError)
        }
    }

    public func updateClips(having ids: [Domain.Clip.Identity], byHiding isHidden: Bool) -> Result<[Domain.Clip], ClipStorageError> {
        do {
            guard case let .success(clips) = try self.fetchClips(for: ids) else {
                self.logger.write(ConsoleLog(level: .error, message: "Failed to update clips to \(isHidden ? "hide" : "show"). Not found."))
                return .failure(.notFound)
            }

            clips.forEach { $0.isHidden = isHidden }

            return .success(clips.compactMap { $0.map(to: Domain.Clip.self) })
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to update clips to \(isHidden ? "hide" : "show"). (error=\(error.localizedDescription))"))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tags to clip. (error=\(error.localizedDescription))
            """))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update clips. (error=\(error.localizedDescription))
            """))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update clips. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateClip(having clipId: Domain.Clip.Identity, byReorderingItemsHaving itemIds: [Domain.ClipItem.Identity]) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(clip) = try self.fetchClip(for: clipId) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                更新対象のクリップが見つからなかったため、クリップ内のアイテムの並び替えに失敗しました (id: \(clipId))
                """))
                return .failure(.notFound)
            }

            let clipItemIds = clip.clipItems?
                .allObjects
                .compactMap { $0 as? Item }
                .compactMap { $0.id } ?? []
            guard Set(clipItemIds) == Set(itemIds) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                引数が不正だったため、クリップ内の並び替えに失敗しました
                - clipId: \(clipId)
                - クリップ内のアイテム数: \(Set(clipItemIds).count)
                - 引数のアイテム数: \(Set(itemIds).count)
                """))
                return .failure(.invalidParameter)
            }

            var currentIndex: Int64 = 1
            for itemId in itemIds {
                guard let item = clip.clipItems?.compactMap({ $0 as? Item }).first(where: { $0.id == itemId }) else {
                    continue
                }
                item.index = currentIndex
                currentIndex += 1
            }

            return .success(())
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update clip. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateClipItems(having ids: [ClipItem.Identity], byUpdatingSiteUrl siteUrl: URL?) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(items) = try self.fetchClipItems(for: ids) else { return .failure(.notFound) }

            for item in items {
                item.siteUrl = siteUrl
                item.updatedDate = Date()
            }

            return .success(())
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update clips. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byAddingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            let albumItems = album.mutableSetValue(forKey: "items")

            guard albumItems.compactMap({ $0 as? AlbumItem }).allSatisfy({
                guard let clip = $0.clip else { return true }
                return clips.contains(clip) == false
            }) else { return .failure(.duplicated) }

            let maxIndex = albumItems
                .compactMap { $0 as? AlbumItem }
                .max(by: { $0.index < $1.index })?
                .index ?? 0
            for (index, clip) in clips.enumerated() {
                let albumItem = AlbumItem(context: self.context)
                albumItem.id = UUID()
                albumItem.index = maxIndex + Int64(index + 1)
                albumItem.clip = clip
                albumItems.add(albumItem)
            }
            album.updatedDate = Date()

            return .success(())
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update album. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byDeletingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else { return .failure(.notFound) }
            guard case let .success(clips) = try self.fetchClips(for: clipIds) else { return .failure(.notFound) }

            let albumItems = album.mutableSetValue(forKey: "items")

            guard clips.allSatisfy({ clip in
                return albumItems.compactMap({ $0 as? AlbumItem }).contains(where: { $0.clip == clip })
            }) else { return .failure(.notFound) }

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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update album. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byReorderingClipsHaving clipIds: [Domain.Clip.Identity]) -> Result<Void, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                更新対象のアルバムが見つからなかったため、アルバム内のアイテムの並び替えに失敗しました (id: \(albumId))
                """))
                return .failure(.notFound)
            }

            let itemIds = album.items?
                .allObjects
                .compactMap { $0 as? AlbumItem }
                .compactMap { $0.clip?.id } ?? []
            guard Set(itemIds) == Set(clipIds) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                引数が不正だったため、アルバム内の並び替えに失敗しました
                - albumId: \(albumId)
                - アルバム内のアイテム数: \(Set(itemIds).count)
                - 引数のアイテム数: \(Set(clipIds).count)
                """))
                return .failure(.invalidParameter)
            }

            var currentIndex: Int64 = 1
            for clipId in clipIds {
                guard let item = album.items?.compactMap({ $0 as? AlbumItem }).first(where: { $0.clip?.id == clipId }) else {
                    continue
                }
                item.index = currentIndex
                currentIndex += 1
            }

            return .success(())
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update album. (error=\(error.localizedDescription))
            """))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update album. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateAlbum(having albumId: Domain.Album.Identity, byHiding isHidden: Bool) -> Result<Domain.Album, ClipStorageError> {
        do {
            guard case let .success(album) = try self.fetchAlbum(for: albumId) else { return .failure(.notFound) }

            album.isHidden = isHidden
            album.updatedDate = Date()

            return .success(album.map(to: Domain.Album.self)!)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update album. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateAlbums(byReordering albumIds: [Domain.Album.Identity]) -> Result<Void, ClipStorageError> {
        do {
            let request: NSFetchRequest<Album> = Album.fetchRequest()
            let albums = try self.context.fetch(request)
            guard Set(albums.compactMap({ $0.id })) == Set(albumIds) else {
                self.logger.write(ConsoleLog(level: .error, message: """
                引数が不正だったため、アルバムの並び替えに失敗しました
                - アルバム数: \(Set(albums.compactMap({ $0.id })).count)
                - 引数のアルバム数: \(Set(albumIds).count)
                """))
                return .failure(.invalidParameter)
            }

            var currentIndex: Int64 = 1
            for albumId in albumIds {
                guard let target = albums.first(where: { $0.id == albumId }) else {
                    continue
                }
                target.index = currentIndex
                currentIndex += 1
            }

            return .success(())
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update album. (error=\(error.localizedDescription))
            """))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update tag. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func updateTag(having id: Domain.Tag.Identity, byHiding isHidden: Bool) -> Result<Domain.Tag, ClipStorageError> {
        do {
            guard case let .success(tag) = try self.fetchTag(for: id) else { return .failure(.notFound) }

            tag.isHidden = isHidden

            return .success(tag.map(to: Domain.Tag.self)!)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add update tag. (error=\(error.localizedDescription))
            """))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to delete clips. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func deleteClipItem(having id: Domain.ClipItem.Identity) -> Result<Domain.ClipItem, ClipStorageError> {
        do {
            guard case let .success(item) = try self.fetchClipItem(for: id) else { return .failure(.notFound) }
            let removeTarget = item.map(to: Domain.ClipItem.self)!

            guard let clipItems = item.clip?.clipItems?.compactMap({ $0 as? Item }).sorted(by: { $0.index < $1.index }) else {
                self.context.delete(item)
                return .success(removeTarget)
            }

            var index: Int64 = 1
            var count: Int64 = 0
            for clipItem in clipItems {
                if clipItem.id == id {
                    self.context.delete(item)
                    continue
                }
                clipItem.index = index
                count += clipItem.imageSize
                index += 1
            }
            item.clip?.imagesSize = count

            return .success(removeTarget)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to delete clip item. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func deleteAlbum(having id: Domain.Album.Identity) -> Result<Domain.Album, ClipStorageError> {
        do {
            let request: NSFetchRequest<Album> = Album.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Album.index, ascending: true)]
            let albums = try self.context.fetch(request)

            var deletedTarget: Domain.Album?
            var currentIndex: Int64 = 1
            for album in albums {
                if deletedTarget != nil {
                    album.index = currentIndex
                    currentIndex += 1
                    continue
                }

                if deletedTarget == nil, album.id == id {
                    deletedTarget = album.map(to: Domain.Album.self)
                    currentIndex = album.index
                    self.context.delete(album)
                    continue
                }
            }

            guard let result = deletedTarget else { return .failure(.notFound) }
            return .success(result)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to delete album. (error=\(error.localizedDescription))
            """))
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
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to delete tags. (error=\(error.localizedDescription))
            """))
            return .failure(.internalError)
        }
    }

    public func deleteAll() -> Result<Void, ClipStorageError> {
        return .failure(.internalError)
    }
}
