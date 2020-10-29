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
    private let imageStorage: ImageStorageProtocol
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
         imageStorage: ImageStorageProtocol,
         thumbnailStorage: ThumbnailStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.itemId = itemId
        self.imageStorage = imageStorage
        self.thumbnailStorage = thumbnailStorage
        self.logger = logger
    }

    // MARK: - Methods

    func resolveImageUrl() -> URL? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        guard let url = try? self.imageStorage.resolveImageFileUrl(named: item.imageFileName, inClipHaving: item.clipId) else {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read image url for preview.
            """))
            self.view?.showErrorMessage(L10n.clipItemPreviewViewErrorAtReadImage)
            return nil
        }
        return url
    }

    func readThumbnailIfExists() -> UIImage? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        return self.thumbnailStorage.readThumbnailIfExists(for: item)
    }

    func readImageData() -> Data? {
        guard let item = self.query.clip.value.items.first(where: { $0.identity == self.itemId }) else { return nil }
        do {
            return try self.imageStorage.readImage(named: item.imageFileName, inClipHaving: item.clipId)
        } catch {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to read image for preview. \(error.localizedDescription)
            """))
            self.view?.showErrorMessage(L10n.clipItemPreviewViewErrorAtReadImage)
            return nil
        }
    }
}
