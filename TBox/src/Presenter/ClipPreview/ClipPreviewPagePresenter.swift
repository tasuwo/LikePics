//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipPreviewPageViewProtocol: AnyObject {
    func reloadPages()

    func showErrorMessage(_ message: String)
}

class ClipPreviewPagePresenter {
    weak var view: ClipPreviewPageViewProtocol?

    private let storage: ClipStorageProtocol
    private let clipUrl: URL

    private(set) var clip: Clip

    // MARK: - Lifecycle

    init(clip: Clip, storage: ClipStorageProtocol) {
        self.clip = clip
        self.clipUrl = clip.url
        self.storage = storage
    }

    // MARK: - Methods

    func reload() {
        switch self.storage.readClip(having: self.clipUrl) {
        case let .success(clip):
            self.clip = clip
            self.view?.reloadPages()
        case let .failure(error):
            self.view?.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }

    private static func resolveErrorMessage(_ error: Error) -> String {
        // TODO: Error Handling
        return "Failed."
    }
}
