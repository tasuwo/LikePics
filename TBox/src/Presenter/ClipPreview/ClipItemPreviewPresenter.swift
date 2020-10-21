//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import UIKit

protocol ClipItemPreviewViewProtocol: AnyObject {
    func showErrorMessage(_ message: String)
}

class ClipItemPreviewPresenter {
    let itemId: ClipItem.Identity

    private let query: ClipQuery
    private let storage: ClipStorageProtocol
    private let cacheStorage: ThumbnailStorageProtocol
    private let logger: TBoxLoggable

    var imageSize: ImageSize? {
        return self.query.clip.value
            .items
            .first(where: { $0.identity == self.itemId })?
            .imageSize
    }

    weak var view: ClipItemPreviewViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipQuery,
         itemId: ClipItem.Identity,
         storage: ClipStorageProtocol,
         cacheStorage: ThumbnailStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.itemId = itemId
        self.storage = storage
        self.cacheStorage = cacheStorage
        self.logger = logger
    }

    // MARK: - Methods

    func resolveImageUrl() -> URL? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        switch self.storage.readImageFileUrl(of: item) {
        case let .success(url):
            return url

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read image url for preview. (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipItemPreviewViewErrorAtReadImage)\n\(error.makeErrorCode())")
            return nil
        }
    }

    func readThumbnailIfExists() -> UIImage? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        return self.cacheStorage.readThumbnailIfExists(for: item)
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
