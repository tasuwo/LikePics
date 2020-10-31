//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class ClipCommandService {
    private let clipStorage: ClipStorageProtocol
    private let lightweightClipStorage: LightweightClipStorageProtocol
    private let imageStorage: ImageStorageProtocol
    private let thumbnailStorage: ThumbnailStorageProtocol
    private let logger: TBoxLoggable
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ClipCommandService")

    public init(clipStorage: ClipStorageProtocol,
                lightweightClipStorage: LightweightClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                thumbnailStorage: ThumbnailStorageProtocol,
                logger: TBoxLoggable)
    {
        self.clipStorage = clipStorage
        self.lightweightClipStorage = lightweightClipStorage
        self.imageStorage = imageStorage
        self.thumbnailStorage = thumbnailStorage
        self.logger = logger
    }
}

extension ClipCommandService: ClipCommandServiceProtocol {
    // MARK: - ClipCommandServiceProtocol

    // MARK: Create

    public func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                guard data.count == Set(data.map { $0.fileName }).count else {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    ファイル名に重複が存在: \(data.map { $0.fileName }.joined(separator: ","))
                    """))
                    return .failure(.invalidParameter)
                }

                let containsFilesFor = { (item: ClipItem) in
                    return data.contains(where: { $0.fileName == item.imageFileName })
                }
                guard clip.items.allSatisfy({ item in containsFilesFor(item) }) else {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Clipに紐付けれた全Itemの画像データが揃っていない:
                    - expected: \(clip.items.map { $0.imageFileName }.joined(separator: ","))
                    - got: \(data.map { $0.fileName }.joined(separator: ","))
                    """))
                    return .failure(.invalidParameter)
                }

                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                let createdClip: Clip
                switch self.clipStorage.create(clip: clip, forced: forced) {
                case let .success(result):
                    createdClip = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                let lightweightClip = LightweightClip(id: createdClip.identity,
                                                      url: createdClip.url,
                                                      tags: createdClip.tags.map { LightweightTag(id: $0.id, name: $0.name) })
                switch self.lightweightClipStorage.create(clip: lightweightClip) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    軽量クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                try? self.imageStorage.deleteAll(inClipHaving: createdClip.identity)
                data.forEach { try? self.imageStorage.save($0.image, asName: $0.fileName, inClipHaving: createdClip.identity) }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
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
                try self.lightweightClipStorage.beginTransaction()

                let tag: Tag
                switch self.clipStorage.create(tagWithName: name) {
                case let .success(result):
                    tag = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.create(tag: .init(id: tag.identity, name: tag.name)) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
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
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byAddingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                switch self.clipStorage.updateClips(having: clipIds, byAddingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.updateClips(having: clipIds, byAddingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                switch self.clipStorage.updateClips(having: clipIds, byDeletingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.updateClips(having: clipIds, byDeletingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                switch self.clipStorage.updateClips(having: clipIds, byReplacingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.updateClips(having: clipIds, byReplacingTagsHaving: tagIds) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
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
                return .failure(.internalError)
            }
        }
    }

    public func updateTag(having id: Tag.Identity, nameTo name: String) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                switch self.clipStorage.updateTag(having: id, nameTo: name) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.updateTag(having: id, nameTo: name) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    // MARK: Delete

    public func deleteClips(having ids: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                let clips: [Clip]
                switch self.clipStorage.deleteClips(having: ids) {
                case let .success(result):
                    clips = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.deleteClips(having: ids) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                let existsFiles = clips
                    .flatMap { $0.items }
                    .allSatisfy { self.imageStorage.imageFileExists(named: $0.imageFileName, inClipHaving: $0.clipId) }
                guard existsFiles else {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(.internalError)
                }

                clips
                    .flatMap { $0.items }
                    .forEach { clipItem in
                        try? self.imageStorage.delete(fileName: clipItem.imageFileName, inClipHaving: clipItem.clipId)
                    }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    public func deleteClipItem(having id: ClipItem.Identity) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()

                let clipItem: ClipItem
                switch self.clipStorage.deleteClipItem(having: id) {
                case let .success(result):
                    clipItem = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                guard self.imageStorage.imageFileExists(named: clipItem.imageFileName, inClipHaving: clipItem.clipId) else {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    return .failure(.internalError)
                }

                try? self.imageStorage.delete(fileName: clipItem.imageFileName, inClipHaving: clipItem.clipId)
                self.thumbnailStorage.deleteThumbnailCacheIfExists(for: clipItem)

                try self.clipStorage.commitTransaction()
                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
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
                return .failure(.internalError)
            }
        }
    }

    public func deleteTags(having ids: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                try self.lightweightClipStorage.beginTransaction()

                switch self.clipStorage.deleteTags(having: ids) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                switch self.lightweightClipStorage.deleteTags(having: ids) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try self.clipStorage.commitTransaction()
                try self.lightweightClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.lightweightClipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }
}
