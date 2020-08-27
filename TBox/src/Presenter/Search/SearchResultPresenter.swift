//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {}

protocol SearchResultPresenterProtocol: ClipsListPresenterProtocol & AddingClipsToAlbumPresenterDelegate {
    func set(view: SearchResultViewProtocol)

    func replaceClips(by clips: [Clip])
}

class SearchResultPresenter: ClipsListPresenter {
    // MARK: - Properties

    // MARK: ClipsListPresenterProtocol

    var clips: [Clip]

    var selectedClips: [Clip]

    var isEditing: Bool

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    var storage: ClipStorageProtocol

    // MARK: Internal

    private weak var internalView: SearchResultViewProtocol?

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.selectedClips = []
        self.storage = storage
        self.isEditing = false
    }
}

extension SearchResultPresenter: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    func set(view: SearchResultViewProtocol) {
        self.internalView = view
    }

    func updateClips(to clips: [Clip]) {
        self.clips = clips
    }

    func replaceClips(by clips: [Clip]) {
        self.clips = clips
        self.internalView?.reload()
    }
}
