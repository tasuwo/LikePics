//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class TemporariesPersistService {
    let temporaryClipStorage: TemporaryClipStorageProtocol
    let temporaryImageStorage: TemporaryImageStorageProtocol
    let clipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: ImageStorageProtocol
    let logger: TBoxLoggable
    let queue: DispatchQueue

    private(set) var isRunning: Bool = false

    weak var observer: TemporariesPersistServiceObserver?

    // MARK: - Lifecycle

    public init(temporaryClipStorage: TemporaryClipStorageProtocol,
                temporaryImageStorage: TemporaryImageStorageProtocol,
                clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                logger: TBoxLoggable,
                queue: DispatchQueue)
    {
        self.temporaryClipStorage = temporaryClipStorage
        self.temporaryImageStorage = temporaryImageStorage
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.imageStorage = imageStorage
        self.logger = logger
        self.queue = queue
    }

    // MARK: - Methods

    private func errorLog(_ message: String) {
        logger.write(ConsoleLog(level: .error, message: message))
    }

    private func infoLog(_ message: String) {
        logger.write(ConsoleLog(level: .info, message: message))
    }

    private func beginTransaction() throws {
        try self.clipStorage.beginTransaction()
        try self.temporaryClipStorage.beginTransaction()
        try self.referenceClipStorage.beginTransaction()
        try self.imageStorage.beginTransaction()
    }

    private func cancelTransaction() throws {
        try self.clipStorage.cancelTransactionIfNeeded()
        try self.temporaryClipStorage.cancelTransactionIfNeeded()
        try self.referenceClipStorage.cancelTransactionIfNeeded()
        try self.imageStorage.cancelTransactionIfNeeded()
    }

    private func commitTransaction() throws {
        try self.clipStorage.commitTransaction()
        try self.temporaryClipStorage.commitTransaction()
        try self.referenceClipStorage.commitTransaction()
        try self.imageStorage.commitTransaction()
    }

    private func cleanTemporaryArea() {
        do {
            try self.temporaryClipStorage.beginTransaction()
            _ = self.temporaryClipStorage.deleteAll()
            try self.temporaryClipStorage.commitTransaction()
        } catch {
            errorLog("一時保存領域のメタ情報の削除に失敗: \(error.localizedDescription)")
        }

        do {
            try self.temporaryImageStorage.deleteAll()
        } catch {
            errorLog("一時保存領域の画像群の削除に失敗: \(error.localizedDescription)")
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
                errorLog("一時保存領域のDirtyなタグ群の取得に失敗")
                return false
            }

            try beginTransaction()

            var succeeds: [ReferenceTag] = []
            var duplicates: [ReferenceTag] = []
            for dirtyTag in dirtyTags {
                switch clipStorage.create(dirtyTag.map(to: Tag.self)) {
                case .success:
                    succeeds.append(dirtyTag)

                case .failure(.duplicated):
                    duplicates.append(dirtyTag)

                case let .failure(error):
                    try cancelTransaction()
                    errorLog("一時保存領域のDirtyなタグ群の永続化に失敗: \(error.localizedDescription)")
                    return false
                }
            }

            if succeeds.isEmpty == false {
                if let error = referenceClipStorage.updateTags(having: succeeds.map({ $0.id }), toDirty: false).failureValue {
                    try cancelTransaction()
                    errorLog("一時保存領域の永続化成功済のタグのDirtyフラグを折るのに失敗: \(error.localizedDescription)")
                    return false
                }
            }

            if duplicates.isEmpty == false {
                if let error = referenceClipStorage.deleteTags(having: duplicates.map { $0.id }).failureValue {
                    try cancelTransaction()
                    errorLog("一時保存領域内の重複した名前を持つタグの削除に失敗: \(error.localizedDescription)")
                    return false
                }
            }

            try commitTransaction()

            return true
        } catch {
            try? cancelTransaction()
            errorLog("一時保存領域のDirtyなタグの永続化中に例外が発生: \(error.localizedDescription)")
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
            errorLog("一時クリップ群の読み取りに失敗した")
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
            errorLog("一部クリップの永続化に失敗した: \(failures.map({ $0.uuidString }).joined(separator: ","))")
            return false
        }

        return true
    }

    private func persist(_ clip: ClipRecipe) -> Bool {
        do {
            try beginTransaction()

            if let error = clipStorage.create(clip: clip).failureValue {
                try? cancelTransaction()
                errorLog("一時保存クリップのメタ情報の移行に失敗: \(error.localizedDescription)")
                return false
            }

            if let error = temporaryClipStorage.deleteClips(having: [clip.id]).failureValue {
                try? cancelTransaction()
                errorLog("一時保存クリップの削除に失敗: \(error.localizedDescription)")
                return false
            }

            autoreleasepool {
                for item in clip.items {
                    guard let data = try? temporaryImageStorage.readImage(named: item.imageFileName, inClipHaving: clip.id) else {
                        // 画像が見つからなかった場合、どうしようもないためスキップに留める
                        infoLog("移行対象の画像が見つかりませんでした。スキップします")
                        continue
                    }

                    // メタデータが正常に移行できていれば画像は復旧可能な可能性が高い点、移動に失敗してもどうしようもない点から、
                    // 画像の移動に失敗した場合でも異常終了とはしない
                    try? imageStorage.create(data, id: item.imageId)
                    try? temporaryImageStorage.delete(fileName: item.imageFileName, inClipHaving: clip.id)
                }
            }

            try? temporaryImageStorage.deleteAll(inClipHaving: clip.id)

            try commitTransaction()

            return true
        } catch {
            try? cancelTransaction()
            errorLog("一時画像の永続化中に例外が発生: \(error.localizedDescription)")
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
        self.queue.sync {
            var result: Bool = false

            self.clipStorage.performAndWait { [weak self] in
                guard let self = self else {
                    result = false
                    return
                }

                guard self.isRunning == false else {
                    self.infoLog("Failed to take execution lock for persistence.")
                    result = true
                    return
                }

                self.isRunning = true
                defer { self.isRunning = false }

                guard self.persistTemporaryDirtyTags() else {
                    result = false
                    return
                }

                guard self.persistTemporaryClips() else {
                    result = false
                    return
                }

                self.cleanTemporaryArea()

                result = true
            }

            return result
        }
    }
}
