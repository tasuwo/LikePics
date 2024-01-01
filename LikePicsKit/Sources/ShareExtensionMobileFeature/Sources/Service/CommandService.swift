//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Foundation
import os.log

class CommandService {
    private let storage: ReferenceClipStorageProtocol
    private let logger = Logger(LogHandler.service)

    // MARK: - Lifecycle

    init(storage: ReferenceClipStorageProtocol) {
        self.storage = storage
    }
}

extension CommandService: TagCommandServiceProtocol {
    // MARK: - TagCommandServiceProtocol

    func create(tagWithName name: String) -> Result<Tag.Identity, TagCommandServiceError> {
        do {
            try self.storage.beginTransaction()

            let id = UUID()

            switch self.storage.create(tag: .init(id: id, name: name, isHidden: false, clipCount: 0, isDirty: true)) {
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

extension CommandService: AlbumCommandServiceProtocol {
    // MARK: - AlbumCommandServiceProtocol

    func create(albumWithTitle title: String) -> Result<Album.Identity, AlbumCommandServiceError> {
        do {
            try self.storage.beginTransaction()

            let id = UUID()

            switch self.storage.create(album: .init(id: id, title: title, isHidden: false, registeredDate: Date(), updatedDate: Date(), isDirty: true)) {
            case .success:
                break

            case .failure(.duplicated):
                try self.storage.cancelTransactionIfNeeded()
                return .failure(.duplicated)

            case let .failure(error):
                try self.storage.cancelTransactionIfNeeded()
                self.logger.error("アルバムの作成に失敗: \(error.localizedDescription, privacy: .public)")

                return .failure(.internalError)
            }

            try self.storage.commitTransaction()

            return .success(id)
        } catch {
            self.logger.error("アルバムの作成に失敗: \(error.localizedDescription, privacy: .public)")
            return .failure(.internalError)
        }
    }
}
