//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol SearchEntryViewProtocol: AnyObject {
    func showErrorMassage(_ message: String)
    func search(with context: SearchContext)
}

class SearchEntryPresenter {
    weak var view: SearchEntryViewProtocol?

    // MARK: - Lifecycle

    init() {}

    // MARK: - Methods

    func search(by text: String) {
        guard !text.isEmpty else { return }
        self.view?.search(with: .keywords(text.split(separator: " ").map { String($0) }))
    }
}
