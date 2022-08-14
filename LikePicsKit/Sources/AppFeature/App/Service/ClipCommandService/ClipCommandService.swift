//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Foundation
import os.log
import Smoothie

public class ClipCommandService {
    let clipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: ImageStorageProtocol
    let diskCache: DiskCaching
    let commandQueue: StorageCommandQueue
    let lock: NSRecursiveLock
    private let logger = Logger(LogHandler.service)

    private(set) var isTransporting = false

    // MARK: - Lifecycle

    public init(clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                diskCache: DiskCaching,
                commandQueue: StorageCommandQueue,
                lock: NSRecursiveLock)
    {
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.imageStorage = imageStorage
        self.diskCache = diskCache
        self.commandQueue = commandQueue
        self.lock = lock
    }
}

extension ClipCommandService {
    func syncTagsClipCount(for ids: Set<Tag.Identity>) {
        do {
            try referenceClipStorage.beginTransaction()

            try clipStorage.readTags(having: ids).get().forEach {
                try referenceClipStorage.updateTag(having: $0.id, clipCountTo: $0.clipCount).get()
            }

            try referenceClipStorage.commitTransaction()
        } catch {
            logger.error("clipCoutの同期に失敗")
        }
    }
}

extension ClipCommandService: ClipCommandServiceProtocol {
    // MARK: - ClipCommandServiceProtocol

    // MARK: Create

    public func create(clip: ClipRecipe, withContainers containers: [ImageContainer], forced: Bool) -> Result<Clip.Identity, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                let containsFilesFor = { (item: ClipItemRecipe) in
                    return containers.contains(where: { $0.id == item.imageId })
                }
                guard clip.items.allSatisfy({ item in containsFilesFor(item) }) else {
                    self.logger.error("クリップの保存に失敗: Clipに紐付けれた全Itemの画像データが揃っていない: ")
                    return .failure(.invalidParameter)
                }

                try self.clipStorage.beginTransaction()
                try self.imageStorage.beginTransaction()

                let clipId = try self.clipStorage.create(clip: clip).get().id

                containers.forEach { container in
                    try? self.imageStorage.create(container.data, id: container.id)
                }

                try self.clipStorage.commitTransaction()
                try self.imageStorage.commitTransaction()

                self.syncTagsClipCount(for: Set(clip.tagIds))

                return .success(clipId)
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの保存に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの保存に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func create(tagWithName name: String) -> Result<Tag.Identity, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let tag = try self.clipStorage.create(tagWithName: name).get()
                let referenceTag = ReferenceTag(
                    id: tag.identity,
                    name: tag.name,
                    isHidden: tag.isHidden,
                    clipCount: tag.clipCount
                )
                _ = try self.referenceClipStorage.create(tag: referenceTag).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(tag.id)
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの作成に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの作成に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func create(albumWithTitle title: String) -> Result<Album.Identity, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let album = try self.clipStorage.create(albumWithTitle: title).get()
                let referenceClip = ReferenceAlbum(
                    id: album.id,
                    title: album.title,
                    isHidden: album.isHidden,
                    registeredDate: album.registeredDate,
                    updatedDate: album.updatedDate
                )
                _ = try self.referenceClipStorage.create(album: referenceClip).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(album.id)
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの作成に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.commitTransaction()
                self.logger.error("アルバムの作成に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    // MARK: Update

    public func updateClips(having ids: [Clip.Identity], byHiding isHidden: Bool) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                _ = try self.clipStorage.updateClips(having: ids, byHiding: isHidden).get()
                try self.clipStorage.commitTransaction()
                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                _ = try self.clipStorage.updateClips(having: clipIds, byAddingTagsHaving: tagIds).get()
                try self.clipStorage.commitTransaction()

                self.syncTagsClipCount(for: Set(tagIds))

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                _ = try self.clipStorage.updateClips(having: clipIds, byDeletingTagsHaving: tagIds).get()
                try self.clipStorage.commitTransaction()

                self.syncTagsClipCount(for: Set(tagIds))

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()

                let updatingTagIds = try? self.clipStorage.readTags(forClipsHaving: clipIds).get().map { $0.id }
                _ = try self.clipStorage.updateClips(having: clipIds, byReplacingTagsHaving: tagIds).get()

                try self.clipStorage.commitTransaction()

                self.syncTagsClipCount(for: Set((updatingTagIds ?? []) + tagIds))

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateClipItems(having ids: [ClipItem.Identity], byUpdatingSiteUrl siteUrl: URL?) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                _ = try self.clipStorage.updateClipItems(having: ids, byUpdatingSiteUrl: siteUrl).get()
                try self.clipStorage.commitTransaction()
                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateClip(having id: Clip.Identity, byReorderingItemsHaving itemIds: [ClipItem.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                _ = try self.clipStorage.updateClip(having: id, byReorderingItemsHaving: itemIds).get()
                try self.clipStorage.commitTransaction()
                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let currentDate = Date()
                _ = try self.clipStorage.updateAlbum(having: albumId, byAddingClipsHaving: clipIds, at: currentDate).get()
                _ = try self.referenceClipStorage.updateAlbum(having: albumId, updatedAt: currentDate).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let currentDate = Date()
                _ = try self.clipStorage.updateAlbum(having: albumId, byDeletingClipsHaving: clipIds, at: currentDate).get()
                _ = try self.referenceClipStorage.updateAlbum(having: albumId, updatedAt: currentDate).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byReorderingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let currentDate = Date()
                _ = try self.clipStorage.updateAlbum(having: albumId, byReorderingClipsHaving: clipIds, at: currentDate).get()
                _ = try self.referenceClipStorage.updateAlbum(having: albumId, updatedAt: currentDate).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let currentDate = Date()
                _ = try self.clipStorage.updateAlbum(having: albumId, titleTo: title, at: currentDate).get()
                _ = try self.referenceClipStorage.updateAlbum(having: albumId, titleTo: title, updatedAt: currentDate).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byHiding isHidden: Bool) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let currentDate = Date()
                _ = try self.clipStorage.updateAlbum(having: albumId, byHiding: isHidden, at: currentDate).get()
                _ = try self.referenceClipStorage.updateAlbum(having: albumId, byHiding: isHidden, updatedAt: currentDate).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbums(byReordering albumIds: [Album.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                _ = try self.clipStorage.updateAlbums(byReordering: albumIds).get()
                _ = try self.referenceClipStorage.updateAlbums(byReordering: albumIds).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                _ = try self.clipStorage.updateTag(having: id, nameTo: name).get()
                _ = try self.referenceClipStorage.updateTag(having: id, nameTo: name).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func updateTag(having id: Tag.Identity, byHiding isHidden: Bool) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                _ = try self.clipStorage.updateTag(having: id, byHiding: isHidden).get()
                _ = try self.referenceClipStorage.updateTag(having: id, byHiding: isHidden).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの更新に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func purgeClipItems(forClipHaving id: Domain.Clip.Identity) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()

                let albumIds = try self.clipStorage.readAlbumIds(containsClipsHaving: [id]).get()
                let originalTags = try self.clipStorage.readTags(forClipHaving: id).get()
                let originalClip = try self.clipStorage.deleteClip(having: id).get()

                let newClips: [ClipRecipe] = originalClip.items.map { item in
                    let clipId = UUID()
                    let date = Date()
                    return ClipRecipe(id: clipId,
                                      description: originalClip.description,
                                      items: [
                                          .init(id: UUID(),
                                                url: item.url,
                                                clipId: clipId,
                                                clipIndex: 0,
                                                imageId: item.imageId,
                                                imageFileName: item.imageFileName,
                                                imageUrl: item.imageUrl,
                                                imageSize: item.imageSize,
                                                imageDataSize: item.imageDataSize,
                                                registeredDate: item.registeredDate,
                                                updatedDate: date)
                                      ],
                                      tagIds: originalTags.map { $0.id },
                                      albumIds: Set(albumIds),
                                      isHidden: originalClip.isHidden,
                                      dataSize: item.imageDataSize,
                                      registeredDate: date,
                                      updatedDate: date)
                }

                try newClips.forEach { _ = try self.clipStorage.create(clip: $0).get() }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの分割に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの分割に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func mergeClipItems(itemIds: [ClipItem.Identity], tagIds: [Tag.Identity], inClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()

                let albumIds = try self.clipStorage.readAlbumIds(containsClipsHaving: clipIds).get()
                let items = try self.clipStorage.readClipItems(having: itemIds).get()
                _ = try self.clipStorage.deleteClips(having: clipIds).get()

                let clipId = UUID()
                let newItems = items.enumerated().map { index, item in
                    return ClipItemRecipe(id: UUID(),
                                          url: item.url,
                                          clipId: clipId,
                                          clipIndex: index + 1,
                                          imageId: item.imageId,
                                          imageFileName: item.imageFileName,
                                          imageUrl: item.imageUrl,
                                          imageSize: item.imageSize,
                                          imageDataSize: item.imageDataSize,
                                          registeredDate: item.registeredDate,
                                          updatedDate: Date())
                }
                let dataSize = newItems
                    .map { $0.imageDataSize }
                    .reduce(0, +)
                let recipe = ClipRecipe(id: clipId,
                                        description: nil,
                                        items: newItems,
                                        tagIds: tagIds,
                                        albumIds: Set(albumIds),
                                        isHidden: false,
                                        dataSize: dataSize,
                                        registeredDate: Date(),
                                        updatedDate: Date())

                _ = try self.clipStorage.create(clip: recipe).get()

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップのマージに失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップのマージに失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    // MARK: Delete

    public func deleteClips(having ids: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.imageStorage.beginTransaction()

                let clips = try self.clipStorage.deleteClips(having: ids).get()

                let existsFiles = try clips
                    .flatMap { $0.items }
                    .allSatisfy { try self.imageStorage.exists(having: $0.imageId) }
                if existsFiles {
                    clips
                        .flatMap { $0.items }
                        .forEach { try? self.imageStorage.delete(having: $0.imageId) }
                } else {
                    self.logger.error("削除中のクリップに対応する画像が見つからなかったため、スキップします")
                }

                try self.clipStorage.commitTransaction()
                try self.imageStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.error("クリップの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func deleteClipItem(_ item: ClipItem) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.imageStorage.beginTransaction()

                _ = try self.clipStorage.deleteClipItem(having: item.id).get()

                guard try self.imageStorage.exists(having: item.imageId) else {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.imageStorage.cancelTransactionIfNeeded()
                    self.logger.error("ClipItemの削除に失敗: 画像が見つからなかった")
                    return .failure(.notFound)
                }

                try? self.imageStorage.delete(having: item.imageId)
                self.diskCache.remove(forKey: "clip-collection-\(item.identity.uuidString)")

                try self.clipStorage.commitTransaction()
                try self.imageStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.error("ClipItemの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.error("ClipItemの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func deleteAlbum(having id: Album.Identity) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                _ = try self.clipStorage.deleteAlbum(having: id).get()
                _ = try self.referenceClipStorage.deleteAlbums(having: [id]).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func deleteTags(having ids: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else {
                return .failure(.internalError)
            }
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                _ = try self.clipStorage.deleteTags(having: ids).get()
                _ = try self.referenceClipStorage.deleteTags(having: ids).get()

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch let error as ClipStorageError {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(error)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.error("タグの削除に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }

    public func deduplicateAlbumItem(albumId: Album.Identity, clipId: Clip.Identity) {
        lock.lock(); defer { lock.unlock() }
        return commandQueue.sync { [weak self] in
            guard let self = self else { return }
            do {
                try self.clipStorage.beginTransaction()
                self.clipStorage.deduplicateAlbumItem(albumId: albumId, clipId: clipId)
                try self.clipStorage.commitTransaction()
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
            }
        }
    }
}

extension ClipCommandService: TagCommandServiceProtocol {
    public func create(tagWithName name: String) -> Result<Tag.Identity, TagCommandServiceError> {
        let result: Result<Tag.Identity, ClipStorageError> = create(tagWithName: name)
        switch result {
        case let .success(tagId):
            return .success(tagId)

        case .failure(.duplicated):
            return .failure(.duplicated)

        default:
            return .failure(.internalError)
        }
    }
}

extension ClipCommandService: AlbumCommandServiceProtocol {
    public func create(albumWithTitle title: String) -> Result<Album.Identity, AlbumCommandServiceError> {
        let result: Result<Album.Identity, ClipStorageError> = create(albumWithTitle: title)
        switch result {
        case let .success(albumId):
            return .success(albumId)

        case .failure(.duplicated):
            return .failure(.duplicated)

        default:
            return .failure(.internalError)
        }
    }
}
