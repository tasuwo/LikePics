//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public class ClipCommandService {
    private let clipStorage: ClipStorageProtocol
    private let imageStorage: ImageStorageProtocol
    private let thumbnailStorage: ThumbnailStorageProtocol
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.ClipCommandService")

    public init(clipStorage: ClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                thumbnailStorage: ThumbnailStorageProtocol)
    {
        self.clipStorage = clipStorage
        self.imageStorage = imageStorage
        self.thumbnailStorage = thumbnailStorage
    }
}

extension ClipCommandService: ClipCommandServiceProtocol {
    // MARK: - ClipCommandServiceProtocol

    // MARK: Create

    public func create(clip: Clip, withData data: [(fileName: String, image: Data)], forced: Bool) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                guard data.count == Set(data.map { $0.fileName }).count else {
                    return .failure(.invalidParameter)
                }

                let containsFilesFor = { (item: ClipItem) in
                    return data.contains(where: { $0.fileName == item.imageFileName })
                }
                guard clip.items.allSatisfy({ item in containsFilesFor(item) }) else {
                    return .failure(.invalidParameter)
                }

                try self.clipStorage.beginTransaction()

                let clipId: Clip.Identity
                switch self.clipStorage.create(clip: clip, forced: forced) {
                case let .success(targetClipId):
                    clipId = targetClipId

                case let .failure(error):
                    try self.clipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                guard data.allSatisfy({ [weak self] e in self?.imageStorage.imageFileExists(named: e.fileName, inClipHaving: clip.identity) == true }) else {
                    try self.clipStorage.cancelTransactionIfNeeded()
                    return .failure(.internalError)
                }

                try? self.imageStorage.deleteAll(inClipHaving: clipId)
                data.forEach { try? self.imageStorage.save($0.image, asName: $0.fileName, inClipHaving: clipId) }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    public func create(tagWithName name: String) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.create(tagWithName: name).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
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
                let result = self.clipStorage.updateClips(having: clipIds, byAddingTagsHaving: tagIds).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byDeletingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateClips(having: clipIds, byDeletingTagsHaving: tagIds).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    public func updateClips(having clipIds: [Clip.Identity], byReplacingTagsHaving tagIds: [Tag.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()
                let result = self.clipStorage.updateClips(having: clipIds, byReplacingTagsHaving: tagIds).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
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
                let result = self.clipStorage.updateTag(having: id, nameTo: name).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }

    // MARK: Delete

    public func deleteClips(having ids: [Clip.Identity]) -> Result<Void, ClipStorageError> {
        return self.queue.sync {
            do {
                try self.clipStorage.beginTransaction()

                let clips: [Clip]
                switch self.clipStorage.deleteClips(having: ids) {
                case let .success(result):
                    clips = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    return .failure(error)
                }

                try clips
                    .flatMap { $0.items }
                    .forEach { clipItem in
                        try self.imageStorage.delete(fileName: clipItem.imageFileName, inClipHaving: clipItem.clipId)
                    }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
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

                try self.imageStorage.delete(fileName: clipItem.imageFileName, inClipHaving: clipItem.clipId)
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
                let result = self.clipStorage.deleteTags(having: ids).map { _ in () }
                try self.clipStorage.commitTransaction()
                return result
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                return .failure(.internalError)
            }
        }
    }
}
