//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

extension ClipCommandService: TemporaryClipsPersistServiceProtocol {
    // MARK: - TemporaryClipsPersistServiceProtocol

    // TODO: 移行できなかったデータを捨てる

    public func persistIfNeeded() {
        self.queue.sync {
            guard self.takeExecutionLock() else {
                self.logger.write(ConsoleLog(level: .info, message: """
                Failed to take execution lock for transportation.
                """))
                return
            }
            defer {
                self.releaseExecutionLock()
            }

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
