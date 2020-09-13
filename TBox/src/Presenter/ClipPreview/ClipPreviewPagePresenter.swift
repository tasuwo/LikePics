//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol ClipPreviewPageViewProtocol: AnyObject {
    func reloadPages()

    func showErrorMessage(_ message: String)
}

class ClipPreviewPagePresenter {
    weak var view: ClipPreviewPageViewProtocol?

    private let clipUrl: URL
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private(set) var clip: Clip

    // MARK: - Lifecycle

    init(clip: Clip, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.clip = clip
        self.clipUrl = clip.url
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    private static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        return L10n.clipPreviewPageViewErrorAtReadClip + "\n(\(error.makeErrorCode()))"
    }

    func reload() {
        switch self.storage.readClip(having: self.clipUrl) {
        case let .success(clip):
            self.clip = clip
            self.view?.reloadPages()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read clip. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }
}
