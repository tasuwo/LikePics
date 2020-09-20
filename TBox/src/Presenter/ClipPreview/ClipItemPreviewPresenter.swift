//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol ClipItemPreviewViewProtocol: AnyObject {
    func showErrorMessage(_ message: String)
}

class ClipItemPreviewPresenter {
    enum FailureContext {
        case readImage
    }

    let clip: Clip
    let item: ClipItem

    weak var view: ClipItemPreviewViewProtocol?
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    // MARK: - Lifecyle

    init(clip: Clip, item: ClipItem, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.clip = clip
        self.item = item
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    private static func resolveErrorMessage(error: ClipStorageError, context: FailureContext) -> String {
        let message: String = {
            switch context {
            case .readImage:
                return L10n.clipItemPreviewViewErrorAtReadImage
            }
        }()
        return message + "\n(\(error.makeErrorCode()))"
    }

    func loadImageData() -> Data? {
        switch self.storage.readImageData(having: self.item.image.url, forClipHaving: self.item.clipUrl) {
        case let .success(data):
            return data

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to load image data. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .readImage))
            return nil
        }
    }
}
