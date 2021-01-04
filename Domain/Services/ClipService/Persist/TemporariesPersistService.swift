//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class TemporariesPersistService {
    let temporaryClipStorage: ClipStorageProtocol
    let temporaryImageStorage: ImageStorageProtocol
    let clipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: NewImageStorageProtocol
    let logger: TBoxLoggable
    let queue: DispatchQueue

    private(set) var isRunning: Bool = false

    // MARK: - Lifecycle

    public init(temporaryClipStorage: ClipStorageProtocol,
                temporaryImageStorage: ImageStorageProtocol,
                clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                imageStorage: NewImageStorageProtocol,
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
        try self.imageStorage.cancelTransactionIfNeeded()
    }

    private func persistTemporaryClips() -> Bool {
        let temporaryClips: [Clip.Identity: Clip]
        switch self.temporaryClipStorage.readAllClips() {
        case let .success(clips):
            temporaryClips = clips.reduce(into: [Clip.Identity: Clip]()) { result, clip in
                result[clip.identity] = clip
            }

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            一時クリップ群の読み取りに失敗: \(error.localizedDescription)
            """))
            return true
        }

        var persistentSkippedClipIds: [Clip.Identity] = []
        for (clipId, _) in temporaryClips {
            guard self.persist(clipId: clipId, in: temporaryClips) else {
                persistentSkippedClipIds.append(clipId)
                continue
            }
        }

        // TODO: 移行に失敗したクリップをエラーログに格納し、復旧できるようにする
        if persistentSkippedClipIds.isEmpty == false {
            self.logger.write(ConsoleLog(level: .error, message: """
            一部クリップの永続化に失敗した: \(persistentSkippedClipIds.map({ $0.uuidString }).joined(separator: ","))
            """))
            return false
        }

        return true
    }

    private func persist(clipId: Clip.Identity, in temporaryClips: [Clip.Identity: Clip]) -> Bool {
        do {
            guard let clip = temporaryClips[clipId] else {
                self.logger.write(ConsoleLog(level: .error, message: """
                Dirtyな参照クリップが一時クリップの中に見つからない
                """))
                return false
            }

            try self.beginTransaction()

            switch self.clipStorage.create(clip: clip) {
            case .success:
                break

            case let .failure(error):
                try? self.cancelTransaction()
                self.logger.write(ConsoleLog(level: .error, message: """
                一時保存クリップのメタ情報の移行に失敗: \(error.localizedDescription)
                """))
                return false
            }

            switch self.temporaryClipStorage.deleteClips(having: [clipId]) {
            case .success:
                break

            case let .failure(error):
                try? self.cancelTransaction()
                self.logger.write(ConsoleLog(level: .error, message: """
                一時保存クリップの削除に失敗: \(error.localizedDescription)
                """))
                return false
            }

            try autoreleasepool {
                for item in clip.items {
                    guard let data = try self.temporaryImageStorage.readImage(named: item.imageFileName, inClipHaving: clip.identity) else {
                        // 画像が見つからなかった場合、どうしようもないためスキップに留める
                        self.logger.write(ConsoleLog(level: .info, message: """
                        移行対象の画像が見つかりませんでした。スキップします
                        """))
                        continue
                    }
                    // メタデータが正常に移行できていれば画像は復旧可能な可能性が高い点、移動に失敗してもどうしようもない点から、
                    // 画像の移動に失敗した場合でも異常終了とはしない
                    try? self.imageStorage.create(data, id: item.imageId)
                    try? self.temporaryImageStorage.delete(fileName: item.imageFileName, inClipHaving: clip.identity)
                }
            }
            try? self.temporaryImageStorage.deleteAll(inClipHaving: clip.identity)

            try self.commitTransaction()

            return true
        } catch {
            try? self.cancelTransaction()
            self.logger.write(ConsoleLog(level: .info, message: """
            一時画像の永続化中に例外が発生: \(error.localizedDescription)
            """))
            return false
        }
    }

    private func persistDirtyTags() -> Bool {
        do {
            let dirtyTags: [ReferenceTag]
            switch self.referenceClipStorage.readAllDirtyTags() {
            case let .success(tags):
                dirtyTags = tags

            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: """
                DirtyTagの取得に失敗: \(error.localizedDescription)
                """))
                return false
            }

            try self.beginTransaction()

            var persistedTags: [ReferenceTag] = []
            var duplicatedTags: [ReferenceTag] = []
            for dirtyTag in dirtyTags {
                switch self.clipStorage.create(dirtyTag.map(to: Tag.self)) {
                case .success:
                    persistedTags.append(dirtyTag)

                case .failure(.duplicated):
                    duplicatedTags.append(dirtyTag)

                case let .failure(error):
                    try self.cancelTransaction()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Dirtyタグの取得に失敗: \(error.localizedDescription)
                    """))
                    return false
                }
            }

            if !persistedTags.isEmpty {
                switch self.referenceClipStorage.updateTags(having: persistedTags.map { $0.id }, toDirty: false) {
                case .success:
                    break

                case let .failure(error):
                    try self.cancelTransaction()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Dirtyフラグの更新に失敗: \(error.localizedDescription)
                    """))
                    return false
                }
            }

            if !duplicatedTags.isEmpty {
                switch self.referenceClipStorage.deleteTags(having: duplicatedTags.map { $0.id }) {
                case .success:
                    break

                case let .failure(error):
                    try self.cancelTransaction()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    重複したDirtyタグの削除に失敗: \(error.localizedDescription)
                    """))
                    return false
                }
            }

            try self.commitTransaction()

            return true
        } catch {
            try? self.cancelTransaction()
            self.logger.write(ConsoleLog(level: .info, message: """
            DirtyTagの永続化中に例外が発生: \(error.localizedDescription)
            """))
            return false
        }
    }

    private func cleanTemporaryArea() {
        do {
            try self.temporaryClipStorage.beginTransaction()
            _ = self.temporaryClipStorage.deleteAll()
            try self.temporaryClipStorage.commitTransaction()
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            一時保存領域のメタ情報の削除に失敗: \(error.localizedDescription)
            """))
        }

        do {
            try self.temporaryImageStorage.deleteAll()
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            一時保存領域の画像群の削除に失敗: \(error.localizedDescription)
            """))
        }
    }
}

extension TemporariesPersistService: TemporariesPersistServiceProtocol {
    // MARK: - TemporariesPersistServiceProtocol

    public func persistIfNeeded() -> Bool {
        self.queue.sync {
            guard self.isRunning == false else {
                self.logger.write(ConsoleLog(level: .info, message: """
                Failed to take execution lock for persistence.
                """))
                return true
            }
            self.isRunning = true
            defer { self.isRunning = false }

            guard self.persistDirtyTags() else { return false }
            guard self.persistTemporaryClips() else { return false }

            self.cleanTemporaryArea()

            return true
        }
    }
}
