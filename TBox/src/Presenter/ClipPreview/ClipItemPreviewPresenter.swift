//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol ClipItemPreviewViewProtocol: AnyObject {
    func showErrorMessage(_ message: String)
}

class ClipItemPreviewPresenter {
    let itemId: ClipItem.Identity

    private let query: ClipQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    weak var view: ClipItemPreviewViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipQuery, itemId: ClipItem.Identity, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.query = query
        self.itemId = itemId
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    func readThumbnailImageData() -> Data? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        switch self.storage.readThumbnailData(of: item) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read thumbnail. (code: \(error.rawValue))
            """))
            return nil
        }
    }

    func readImageData() -> Data? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        switch self.storage.readImageData(of: item) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read image for preview. (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipItemPreviewViewErrorAtReadImage)\n\(error.makeErrorCode())")
            return nil
        }
    }
}
