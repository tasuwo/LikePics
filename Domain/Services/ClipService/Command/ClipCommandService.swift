//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class ClipCommandService {
    let clipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: NewImageStorageProtocol
    let thumbnailStorage: ThumbnailStorageProtocol
    let logger: TBoxLoggable
    let queue: DispatchQueue

    private(set) var isTransporting: Bool = false

    // MARK: - Lifecycle

    public init(clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                imageStorage: NewImageStorageProtocol,
                thumbnailStorage: ThumbnailStorageProtocol,
                logger: TBoxLoggable,
                queue: DispatchQueue)
    {
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.imageStorage = imageStorage
        self.thumbnailStorage = thumbnailStorage
        self.logger = logger
        self.queue = queue
    }
}

extension ClipCommandService: ClipCommandServiceProtocol {
    // MARK: - ClipCommandServiceProtocol

    // MARK: Create

    public func create(clip: Clip, withContainers containers: [ImageContainer], forced: Bool) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                let containsFilesFor = { (item: ClipItem) in
                    return containers.contains(where: { $0.id == item.imageId })
                }
                guard clip.items.allSatisfy({ item in containsFilesFor(item) }) else {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Clipに紐付けれた全Itemの画像データが揃っていない:
                    - expected: \(clip.items.map { $0.id.uuidString }.joined(separator: ","))
                    - got: \(containers.map { $0.id.uuidString }.joined(separator: ","))
                    """))
                    return .failure(.invalidParameter)
                }

                try self.clipStorage.beginTransaction()
                try self.imageStorage.beginTransaction()

                switch self.clipStorage.create(clip: clip) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.imageStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                containers.forEach { container in
                    try? self.imageStorage.create(container.data, id: container.id)
                }

                try self.clipStorage.commitTransaction()
                try self.imageStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                クリップの保存に失敗: \(error.localizedDescription)
                """))
                return .failure(.internalError)
            }
        }
    }

    public func create(tagWithName name: String) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                let tag: Tag
                switch self.clipStorage.create(tagWithName: name) {
                case let .success(result):
                    tag = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to create tag. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                switch self.referenceClipStorage.create(tag: .init(id: tag.identity, name: tag.name)) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to create tag. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to create tag. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func create(albumWithTitle title: String) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.create(albumWithTitle: title).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to create album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    // MARK: Update

    public func updateClips(having ids: [Clip.Identity], byHiding isHidden: Bool) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateClips(having: ids, byHiding: isHidden).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to \(isHidden ? "hide" : "show") clips. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()

                switch self.clipStorage.updateClips(having: clipIds, byAddingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to update clips. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update clips. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()

                switch self.clipStorage.updateClips(having: clipIds, byDeletingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to update clips. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update clips. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()

                switch self.clipStorage.updateClips(having: clipIds, byReplacingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to update clips. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update clips. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateClipItems(having ids: [ClipItem.Identity], byUpdatingSiteUrl siteUrl: URL?) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateClipItems(having: ids, byUpdatingSiteUrl: siteUrl)
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byAddingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateAlbum(having: albumId, byAddingClipsHaving: clipIds).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byDeletingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateAlbum(having: albumId, byDeletingClipsHaving: clipIds).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, byReorderingClipsHaving clipIds: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateAlbum(having: albumId, byReorderingClipsHaving: clipIds).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateAlbum(having albumId: Album.Identity, titleTo title: String) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateAlbum(having: albumId, titleTo: title).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                switch self.clipStorage.updateTag(having: id, nameTo: name) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to update tag. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                switch self.referenceClipStorage.updateTag(having: id, nameTo: name) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to update tag. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to update tag. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    // MARK: Delete

    public func deleteClips(having ids: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.imageStorage.beginTransaction()

                let clips: [Clip]
                switch self.clipStorage.deleteClips(having: ids) {
                case let .success(result):
                    clips = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.imageStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clips. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                let existsFiles = try clips
                    .flatMap { $0.items }
                    .allSatisfy { try self.imageStorage.exists(having: $0.imageId) }
                guard existsFiles else {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.imageStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clips. No image files found.
                    """))
                    return .failure(.internalError)
                }

                clips
                    .flatMap { $0.items }
                    .forEach { try? self.imageStorage.delete(having: $0.imageId) }

                try self.clipStorage.commitTransaction()
                try self.imageStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to delete clips. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func deleteClipItem(_ item: ClipItem) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.imageStorage.beginTransaction()

                let clipItem: ClipItem
                switch self.clipStorage.deleteClipItem(having: item.id) {
                case let .success(result):
                    clipItem = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.imageStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clip item. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                guard try self.imageStorage.exists(having: item.imageId) else {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.imageStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clip item. Image not found.
                    """))
                    return .failure(.internalError)
                }

                try? self.imageStorage.delete(having: item.imageId)
                self.thumbnailStorage.deleteThumbnailCacheIfExists(for: clipItem)

                try self.clipStorage.commitTransaction()
                try self.imageStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.imageStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to delete clip item. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func deleteAlbum(having id: Album.Identity) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.deleteAlbum(having: id).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to delete album. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }

    public func deleteTags(having ids: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                switch self.clipStorage.deleteTags(having: ids) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete tags. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                switch self.referenceClipStorage.deleteTags(having: ids) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete tags. (error=\(error.localizedDescription))
                    """))
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                Failed to delete tags. (error=\(error.localizedDescription))
                """))
                return .failure(.internalError)
            }
        }
    }
}
