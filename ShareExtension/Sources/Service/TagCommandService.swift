//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

class TagCommandService {
    private let storage: ReferenceClipStorageProtocol
    private let logger: Loggable

    // MARK: - Lifecycle

    init(storage: ReferenceClipStorageProtocol, logger: Loggable) {
        self.storage = storage
        self.logger = logger
    }
}

extension TagCommandService: TagCommandServiceProtocol {
    // MARK: - TagCommandServiceProtocol

    func create(tagWithName name: String) -> Result<Void, TagCommandServiceError> {
        do {
            try self.storage.beginTransaction()

            switch self.storage.create(tag: .init(id: UUID(), name: name, isHidden: false, isDirty: true)) {
            case .success:
                break

            case .failure(.duplicated):
                try self.storage.cancelTransactionIfNeeded()
                return .failure(.duplicated)

            case let .failure(error):
                try self.storage.cancelTransactionIfNeeded()
                self.logger.write(ConsoleLog(level: .error, message: """
                タグの作成に失敗: \(error.localizedDescription)
                """))
                return .failure(.internalError)
            }

            try self.storage.commitTransaction()

            return .success(())
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            タグの作成に失敗: \(error.localizedDescription)
            """))
            return .failure(.internalError)
        }
    }
}
