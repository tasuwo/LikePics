//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Foundation
import os.log

public class TemporaryClipCommandService {
    private let clipStorage: TemporaryClipStorageProtocol
    private let imageStorage: TemporaryImageStorageProtocol
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.TemporaryClipCommandService")
    private let logger = Logger(LogHandler.service)

    public init(clipStorage: TemporaryClipStorageProtocol,
                imageStorage: TemporaryImageStorageProtocol)
    {
        self.clipStorage = clipStorage
        self.imageStorage = imageStorage
    }
}

extension TemporaryClipCommandService: TemporaryClipCommandServiceProtocol {
    // MARK: - TemporaryClipCommandServiceProtocol

    public func create(clip: ClipRecipe, withContainers containers: [ImageContainer], forced: Bool) -> Result<Clip.Identity, ClipStorageError> {
        return self.queue.sync {
            do {
                let containsFilesFor = { (item: ClipItemRecipe) in
                    return containers.contains(where: { $0.id == item.imageId })
                }
                guard clip.items.allSatisfy({ item in containsFilesFor(item) }) else {
                    self.logger.error("Clipに紐付けれた全Itemの画像データが揃っていない")
                    return .failure(.invalidParameter)
                }

                try self.clipStorage.beginTransaction()

                let createdClip: ClipRecipe
                switch self.clipStorage.create(clip: clip) {
                case let .success(result):
                    createdClip = result

                case let .failure(error):
                    try? self.clipStorage.cancelTransactionIfNeeded()
                    self.logger.error("一時クリップの保存に失敗: \(error.localizedDescription, privacy: .public)")
                    return .failure(error)
                }

                try? self.imageStorage.deleteAll(inClipHaving: createdClip.id)
                try containers.forEach { container in
                    guard let item = clip.items.first(where: { $0.imageId == container.id }) else { return }
                    try self.imageStorage.save(container.data, asName: item.imageFileName, inClipHaving: createdClip.id)
                }

                try self.clipStorage.commitTransaction()

                return .success(createdClip.id)
            } catch {
                try? self.clipStorage.cancelTransactionIfNeeded()
                self.logger.error("一時クリップの保存に失敗: \(error.localizedDescription, privacy: .public)")
                return .failure(.internalError)
            }
        }
    }
}
