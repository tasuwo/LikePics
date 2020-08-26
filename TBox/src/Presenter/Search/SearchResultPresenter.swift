//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {}

protocol SearchResultPresenterProtocol: ClipsListPreviewablePresenter {
    func set(view: SearchResultViewProtocol)
}

class SearchResultPresenter: ClipsListPresenter & SelectedClipContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: SelectedClipContainer

    var selectedClip: Clip?

    // MARK: Internal

    private weak var internalView: SearchResultViewProtocol?

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
