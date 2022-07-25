//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Foundation
import os.log

public class TemporariesPersistService {
    let temporaryClipStorage: TemporaryClipStorageProtocol
    let temporaryImageStorage: TemporaryImageStorageProtocol
    let clipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: ImageStorageProtocol
    let commandQueue: StorageCommandQueue
    let lock: NSRecursiveLock
    private let logger = Logger(LogHandler.service)

    private(set) var isRunning = false

    weak var observer: TemporariesPersistServiceObserver?

    // MARK: - Lifecycle

    public init(temporaryClipStorage: TemporaryClipStorageProtocol,
                temporaryImageStorage: TemporaryImageStorageProtocol,
                clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                commandQueue: StorageCommandQueue,
                lock: NSRecursiveLock)
    {
        self.temporaryClipStorage = temporaryClipStorage
        self.temporaryImageStorage = temporaryImageStorage
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.imageStorage = imageStorage
        self.commandQueue = commandQueue
        self.lock = lock
    }

    // MARK: - Methods

    private func beginTransaction() throws {
        try commandQueue.sync { [weak self] in try self?.clipStorage.beginTransaction() }
        try temporaryClipStorage.beginTransaction()
        try referenceClipStorage.beginTransaction()
        try commandQueue.sync { [weak self] in try self?.imageStorage.beginTransaction() }
    }

    private func cancelTransaction() throws {
        try commandQueue.sync { [weak self] in try self?.clipStorage.cancelTransactionIfNeeded() }
        try temporaryClipStorage.cancelTransactionIfNeeded()
        try referenceClipStorage.cancelTransactionIfNeeded()
        try commandQueue.sync { [weak self] in try self?.imageStorage.cancelTransactionIfNeeded() }
    }

    private func commitTransaction() throws {
        try commandQueue.sync { [weak self] in try self?.clipStorage.commitTransaction() }
        try temporaryClipStorage.commitTransaction()
        try referenceClipStorage.commitTransaction()
        try commandQueue.sync { [weak self] in try self?.imageStorage.commitTransaction() }
    }

    private func cleanTemporaryArea() {
        do {
            try temporaryClipStorage.beginTransaction()
            _ = temporaryClipStorage.deleteAll()
            try temporaryClipStorage.commitTransaction()
        } catch {
            self.logger.error("一時保存領域のメタ情報の削除に失敗: \(error.localizedDescription)")
        }

        do {
            try temporaryImageStorage.deleteAll()
        } catch {
            logger.error("一時保存領域の画像群の削除に失敗: \(error.localizedDescription)")
        }
    }
}

// MARK: Persist Tags

extension TemporariesPersistService {
    /**
     * - Note: テスト用にアクセスレベルを緩めてある
     */
    func persistTemporaryDirtyTags() -> Bool {
        do {
            guard let dirtyTags = referenceClipStorage.readAllDirtyTags().successValue else {
                logger.error("一時保存領域のDirtyなタグ群の取得に失敗")
                return false
            }

            try beginTransaction()

            var succeeds: [ReferenceTag] = []
            var duplicates: [ReferenceTag] = []
            for dirtyTag in dirtyTags {
                switch commandQueue.sync({ [weak self] in self?.clipStorage.create(dirtyTag.map(to: Tag.self)) }) {
                case .success:
                    succeeds.append(dirtyTag)

                case .failure(.duplicated):
                    duplicates.append(dirtyTag)

                case let .failure(error):
                    try cancelTransaction()
                    logger.error("一時保存領域のDirtyなタグ群の永続化に失敗: \(error.localizedDescription)")
                    return false

                case .none:
                    try cancelTransaction()
                    logger.error("一時保存領域のDirtyなタグ群の永続化に失敗")
                    return false
                }
            }

            if succeeds.isEmpty == false {
                if let error = referenceClipStorage.updateTags(having: succeeds.map({ $0.id }), toDirty: false).failureValue {
                    try cancelTransaction()
                    logger.error("一時保存領域の永続化成功済のタグのDirtyフラグを折るのに失敗: \(error.localizedDescription)")
                    return false
                }
            }

            if duplicates.isEmpty == false {
                if let error = referenceClipStorage.deleteTags(having: duplicates.map { $0.id }).failureValue {
                    try cancelTransaction()
                    logger.error("一時保存領域内の重複した名前を持つタグの削除に失敗: \(error.localizedDescription)")
                    return false
                }
            }

            try commitTransaction()

            return true
        } catch {
            try? cancelTransaction()
            logger.error("一時保存領域のDirtyなタグの永続化中に例外が発生: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Persist Clips

extension TemporariesPersistService {
    /**
     * - Note: テストのためにアクセスレベルを緩めてある
     */
    func persistTemporaryClips() -> Bool {
        guard let temporaryClips = temporaryClipStorage.readAllClips().successValue else {
            logger.error("一時クリップ群の読み取りに失敗した")
            return false
        }

        var failures: [Clip.Identity] = []
        for (index, clip) in temporaryClips.enumerated() {
            observer?.temporariesPersistService(self, didStartThe: index + 1, outOf: temporaryClips.count)

            let isSucceeded = persist(clip)

            if isSucceeded == false {
                failures.append(clip.id)
            }
        }

        if failures.isEmpty == false {
            logger.error("一部クリップの永続化に失敗した: \(failures.map({ $0.uuidString }).joined(separator: ","))")
            return false
        }

        return true
    }

    private func persist(_ clip: ClipRecipe) -> Bool {
        do {
            try beginTransaction()

            if let error = commandQueue.sync({ [weak self] in self?.clipStorage.create(clip: clip) })?.failureValue {
                try? cancelTransaction()
                logger.error("一時保存クリップのメタ情報の移行に失敗: \(error.localizedDescription)")
                return false
            }

            if let error = temporaryClipStorage.deleteClips(having: [clip.id]).failureValue {
                try? cancelTransaction()
                logger.error("一時保存クリップの削除に失敗: \(error.localizedDescription)")
                return false
            }

            for item in clip.items {
                autoreleasepool {
                    guard let data = try? temporaryImageStorage.readImage(named: item.imageFileName, inClipHaving: clip.id) else {
                        // 画像が見つからなかった場合、どうしようもないためスキップに留める
                        logger.debug("移行対象の画像が見つかりませんでした。スキップします")
                        return
                    }

                    // メタデータが正常に移行できていれば画像は復旧可能な可能性が高い点、移動に失敗してもどうしようもない点から、
                    // 画像の移動に失敗した場合でも異常終了とはしない
                    try? commandQueue.sync { [weak self] in try self?.imageStorage.create(data, id: item.imageId) }
                    try? temporaryImageStorage.delete(fileName: item.imageFileName, inClipHaving: clip.id)
                }
            }

            try? temporaryImageStorage.deleteAll(inClipHaving: clip.id)

            try commitTransaction()

            return true
        } catch {
            try? cancelTransaction()
            logger.error("一時画像の永続化中に例外が発生: \(error.localizedDescription)")
            return false
        }
    }
}

extension TemporariesPersistService: TemporariesPersistServiceProtocol {
    // MARK: - TemporariesPersistServiceProtocol

    public func set(observer: TemporariesPersistServiceObserver) {
        self.observer = observer
    }

    public func persistIfNeeded() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        guard self.isRunning == false else {
            logger.debug("Failed to take execution lock for persistence.")
            return true
        }

        isRunning = true
        defer { isRunning = false }

        guard persistTemporaryDirtyTags() else {
            return false
        }

        guard persistTemporaryClips() else {
            return false
        }

        cleanTemporaryArea()

        return true
    }
}
