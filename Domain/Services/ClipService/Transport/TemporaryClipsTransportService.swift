//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class TemporaryClipsPersistService {
    let temporaryClipStorage: ClipStorageProtocol
    let temporaryImageStorage: ImageStorageProtocol
    let clipStorage: ClipStorageProtocol
    let referenceClipStorage: ReferenceClipStorageProtocol
    let imageStorage: ImageStorageProtocol
    let logger: TBoxLoggable
    let queue: DispatchQueue

    private(set) var isRunning: Bool = false

    // MARK: - Lifecycle

    public init(temporaryClipStorage: ClipStorageProtocol,
                temporaryImageStorage: ImageStorageProtocol,
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
}

extension TemporaryClipsPersistService: TemporaryClipsPersistServiceProtocol {
    // MARK: - TemporaryClipsPersistServiceProtocol

    // TODO: 移行できなかったデータを捨てる

    public func persistIfNeeded() {
        self.queue.sync {
            guard self.isRunning == false else {
                self.logger.write(ConsoleLog(level: .info, message: """
                Failed to take execution lock for transportation.
                """))
                return
            }
            self.isRunning = true
            defer { self.isRunning = false }

            do {
                let clips: [Clip]
                switch self.temporaryClipStorage.readAllClips() {
                case let .success(result):
                    clips = result

                case let .failure(error):
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時保存クリップ群の読み取りに失敗: \(error.localizedDescription)
                    """))
                    return
                }

                guard !clips.isEmpty else { return }

                try self.clipStorage.beginTransaction()
                try self.temporaryClipStorage.beginTransaction()
                try self.referenceClipStorage.beginTransaction()

                for clip in clips {
                    switch self.clipStorage.create(clip: clip, allowTagCreation: false, overwrite: true) {
                    case .success:
                        break

                    case let .failure(error):
                        try? self.clipStorage.cancelTransactionIfNeeded()
                        try? self.temporaryClipStorage.cancelTransactionIfNeeded()
                        try? self.referenceClipStorage.cancelTransactionIfNeeded()
                        self.logger.write(ConsoleLog(level: .error, message: """
                        一時保存クリップのメタ情報の移行に失敗: \(error.localizedDescription)
                        """))
                        return
                    }
                }

                switch self.temporaryClipStorage.deleteClips(having: clips.map { $0.identity }) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.temporaryClipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時保存クリップの削除に失敗: \(error.localizedDescription)
                    """))
                    return
                }

                switch self.referenceClipStorage.updateClips(having: clips.map { $0.identity }, byUpdatingDirty: false) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.temporaryClipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    参照クリップのisDirty更新に失敗: \(error.localizedDescription)
                    """))
                    return
                }

                // TODO: 本当にこれで良いか？
                switch self.temporaryClipStorage.deleteAllTags() {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.temporaryClipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時保存領域のタグの削除に失敗: \(error.localizedDescription)
                    """))
                    return
                }

                let allImagesExists = clips
                    .flatMap { $0.items }
                    .allSatisfy { self.temporaryImageStorage.imageFileExists(named: $0.imageFileName, inClipHaving: $0.clipId) == true }
                guard allImagesExists else {
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.temporaryClipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時保存領域に移行対象の画像が存在しない
                    """))
                    return
                }

                for clip in clips {
                    try? self.imageStorage.deleteAll(inClipHaving: clip.identity)
                    for item in clip.items {
                        guard let source = try self.temporaryImageStorage.resolveImageFileUrl(named: item.imageFileName, inClipHaving: clip.identity) else {
                            self.logger.write(ConsoleLog(level: .info, message: """
                            移行対象の画像が見つかりませんでした。移行をスキップします
                            """))
                            continue
                        }
                        try self.imageStorage.moveImageFile(at: source, withName: item.imageFileName, toClipHaving: item.clipId)
                    }
                }

                try self.clipStorage.commitTransaction()
                try self.temporaryClipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()
            } catch {
                self.logger.write(ConsoleLog(level: .info, message: """
                一時保存領域からのクリップの移行に失敗: \(error.localizedDescription)
                """))
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.temporaryClipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                return
            }
        }
    }
}
