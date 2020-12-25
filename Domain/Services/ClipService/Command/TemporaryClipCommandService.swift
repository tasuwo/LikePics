//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public class TemporaryClipCommandService {
    private let clipStorage: ClipStorageProtocol
    private let imageStorage: ImageStorageProtocol
    private let logger: TBoxLoggable
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.TemporaryClipCommandService")

    public init(clipStorage: ClipStorageProtocol,
                imageStorage: ImageStorageProtocol,
                logger: TBoxLoggable)
    {
        self.clipStorage = clipStorage
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

                let createdClip: Clip
                switch self.clipStorage.create(clip: clip) {
                case let .success(result):
                    createdClip = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    self.logger.write(ConsoleLog(level: .error, message: """
                    一時クリップの保存に失敗: \(error.localizedDescription)
                    """))
                    return .failure(error)
                }

                try? self.imageStorage.deleteAll(inClipHaving: createdClip.identity)
                containers.forEach { container in
                    guard let item = clip.items.first(where: { $0.imageId == container.id }) else { return }
                    try? self.imageStorage.save(container.data, asName: item.imageFileName, inClipHaving: createdClip.identity)
                }

                try self.clipStorage.commitTransaction()

                return .success(())
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                一時クリップの保存に失敗: \(error.localizedDescription)
                """))
                return .failure(.internalError)
            }
        }
    }
}
