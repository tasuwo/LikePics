//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Foundation
import os.log

class TagCommandService {
    private let storage: ReferenceClipStorageProtocol
    private let logger = Logger(LogHandler.service)

    // MARK: - Lifecycle

    init(storage: ReferenceClipStorageProtocol) {
        self.storage = storage
    }
}

extension TagCommandService: TagCommandServiceProtocol {
    // MARK: - TagCommandServiceProtocol

    func create(tagWithName name: String) -> Result<Tag.Identity, TagCommandServiceError> {
        do {
            try self.storage.beginTransaction()

            let id = UUID()

            switch self.storage.create(tag: .init(id: id, name: name, isHidden: false, isDirty: true)) {
            case .success:
                break

            case .failure(.duplicated):
                try self.storage.cancelTransactionIfNeeded()
                return .failure(.duplicated)

            case let .failure(error):
                try self.storage.cancelTransactionIfNeeded()
                self.logger.error("タグの作成に失敗: \(error.localizedDescription, privacy: .public)")

                return .failure(.internalError)
            }

            try self.storage.commitTransaction()

            return .success(id)
        } catch {
            self.logger.error("タグの作成に失敗: \(error.localizedDescription, privacy: .public)")
            return .failure(.internalError)
        }
    }
}
