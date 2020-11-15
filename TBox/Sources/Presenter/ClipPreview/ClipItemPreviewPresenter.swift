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

    var itemUrl: URL? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        return item.url
    }

    private let query: ClipQuery
    private let imageQueryService: NewImageQueryServiceProtocol
    private let thumbnailStorage: ThumbnailStorageProtocol
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
         imageQueryService: NewImageQueryServiceProtocol,
         thumbnailStorage: ThumbnailStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.itemId = itemId
        self.imageQueryService = imageQueryService
        self.thumbnailStorage = thumbnailStorage
        self.logger = logger
    }

    // MARK: - Methods

    func readThumbnailIfExists() -> UIImage? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        return self.thumbnailStorage.readThumbnailIfExists(for: item)
    }

    func readImageData() -> Data? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        do {
            return try self.imageQueryService.read(having: item.imageId)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read image for preview. \(error.localizedDescription)
            """))
            self.view?.showErrorMessage(L10n.clipItemPreviewViewErrorAtReadImage)
            return nil
        }
    }
}
