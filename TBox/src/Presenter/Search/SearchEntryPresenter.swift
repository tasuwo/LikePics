//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol SearchEntryViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func showErrorMassage(_ message: String)
    func showReuslt(_ clips: [Clip], withContext: SearchContext)
}

class SearchEntryPresenter {
    weak var view: SearchEntryViewProtocol?

    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    private static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        return L10n.searchEntryViewErrorAtSearch + "\n(\(error.makeErrorCode()))"
    }

    func search(by text: String) {
        guard let view = self.view else { return }
        guard !text.isEmpty else { return }

        view.startLoading()
        let keywords = text.split(separator: " ").map { String($0) }
        switch self.storage.searchClips(byKeywords: keywords) {
        case let .success(clips):
            view.showReuslt(clips.sorted(by: { $0.registeredDate > $1.registeredDate }), withContext: .keyword(keyword: text))

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to search. (code: \(error.rawValue))"))
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }
}
