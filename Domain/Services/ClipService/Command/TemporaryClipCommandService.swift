//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class TemporaryClipCommandService {
    private let clipStorage: ClipStorageProtocol
    private let referenceClipStorage: ReferenceClipStorageProtocol
    private let imageStorage: ImageStorageProtocol
    private let logger: TBoxLoggable
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.TemporaryClipCommandService")

    public init(clipStorage: ClipStorageProtocol,
                referenceClipStorage: ReferenceClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                logger: TBoxLoggable)
    {
        self.clipStorage = clipStorage
        self.referenceClipStorage = referenceClipStorage
        self.imageStorage = imageStorage
        self.logger = logger
    }
}

extension TemporaryClipCommandService: TemporaryClipCommandServiceProtocol {
    // MARK: - TemporaryClipCommandServiceProtocol

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
                try self.referenceClipStorage.beginTransaction()

                let createdClip: Clip
                switch self.clipStorage.create(clip: clip, allowTagCreation: true, overwrite: forced) {
                case let .success(result):
                    createdClip = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                let referenceClip = ReferenceClip(id: createdClip.identity,
                                                  url: createdClip.url,
                                                  description: createdClip.description,
                                                  tags: createdClip.tags.map { ReferenceTag(id: $0.id, name: $0.name) },
                                                  isHidden: createdClip.isHidden,
                                                  registeredDate: createdClip.registeredDate,
                                                  isDirty: true)
                switch self.referenceClipStorage.create(clip: referenceClip) {
                case .success:
                    break

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    軽量クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                try? self.imageStorage.deleteAll(inClipHaving: createdClip.identity)
                data.forEach { try? self.imageStorage.save($0.image, asName: $0.fileName, inClipHaving: createdClip.identity) }

                try self.clipStorage.commitTransaction()
                try self.referenceClipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                try? self.referenceClipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                一時クリップの保存に失敗: \(error.localizedDescription)
                """))
                return .failure(.internalError)
            }
        }
    }
}
