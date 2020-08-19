//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchEntryViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func showErrorMassage(_ message: String)
    func showReuslt(_ clips: [Clip])
}

class SearchEntryPresenter {
    weak var view: SearchEntryViewProtocol?

    private let storage: ClipStorageProtocol

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    func search(_ keywords: [String]) {
        guard let view = self.view else { return }

        view.startLoading()
        switch self.storage.searchClip(byKeywords: keywords) {
        case let .success(clips):
            view.showReuslt(clips.sorted(by: { $0.registeredDate > $1.registeredDate }))
        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }

    private static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}
