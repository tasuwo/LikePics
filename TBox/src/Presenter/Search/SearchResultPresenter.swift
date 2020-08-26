//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {}

protocol SearchResultPresenterProtocol: ClipsListPreviewablePresenter {
    func set(view: SearchResultViewProtocol)
}

class SearchResultPresenter: ClipsListPresenter & ClipsListPreviewableContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: ClipsListPreviewableContainer

    var selectedClip: Clip?

    // MARK: Internal

    private weak var internalView: SearchResultViewProtocol?

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }
}

extension SearchResultPresenter: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    func set(view: SearchResultViewProtocol) {
        self.internalView = view
    }
}
