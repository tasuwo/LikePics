//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {
    func reload()
}

protocol SearchResultPresenterProtocol: ClipsListPreviewablePresenter {
    func set(view: SearchResultViewProtocol)

    func replaceClips(by clips: [Clip])
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

    func replaceClips(by clips: [Clip]) {
        self.clips = clips
        self.internalView?.reload()
    }
}
