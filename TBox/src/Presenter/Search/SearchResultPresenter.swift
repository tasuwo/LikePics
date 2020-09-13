//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {}

enum SearchContext {
    case keyword(keyword: String)
    case tag(tagName: String)
    case album(albumName: String)
}

protocol SearchResultPresenterProtocol: ClipsListPresenterProtocol & AddingClipsToAlbumPresenterDelegate {
    var context: SearchContext { get }

    func set(view: SearchResultViewProtocol)

    func replaceClips(by clips: [Clip])
}

class SearchResultPresenter: ClipsListPresenter {
    // MARK: - Properties

    var context: SearchContext

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

    init(context: SearchContext, clips: [Clip], storage: ClipStorageProtocol) {
        self.context = context
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
