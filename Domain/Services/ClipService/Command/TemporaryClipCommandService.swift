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
                try self.referenceClipStorage.beginTransaction()

                let createdClip: Clip
                switch self.clipStorage.create(clip: clip, allowTagCreation: true, overwrite: forced) {
                case let .success(result):
                    createdClip = result.new

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    try? self.referenceClipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                let referenceClip = ReferenceClip(id: createdClip.identity,
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
                containers.forEach { container in
                    guard let item = clip.items.first(where: { $0.imageId == container.id }) else { return }
                    try? self.imageStorage.save(container.data, asName: item.imageFileName, inClipHaving: createdClip.identity)
                }

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
