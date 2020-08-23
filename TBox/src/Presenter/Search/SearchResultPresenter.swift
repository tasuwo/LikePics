//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {}

protocol SearchResultPresenterProtocol: ClipsListDisplayablePresenter {
    func set(view: SearchResultViewProtocol)
}

class SearchResultPresenter: ClipsListPresenter {
    weak var internalView: SearchResultViewProtocol?

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }

    static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}

extension SearchResultPresenter: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    func set(view: SearchResultViewProtocol) {
        self.internalView = view
    }
}
