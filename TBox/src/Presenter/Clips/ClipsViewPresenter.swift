//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func showErrorMassage(_ message: String)
    func reload()
}

class ClipsPresenter {
    weak var view: ClipsViewProtocol?

    private let storage: ClipStorageProtocol

    private(set) var clips: [Clip] = []

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    func reload() {
        guard let view = self.view else { return }

        view.startLoading()
        switch self.storage.readAllClips() {
        case let .success(clips):
            self.clips = clips
            view.reload()
        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }

    private static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        return "問題が発生しました"
    }
}
