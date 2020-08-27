//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultEditViewProtocol: ClipsListEditableViewProtocol {}

protocol SearchResultEditPresenterProtocol: ClipsListEditablePresenter {
    func set(view: SearchResultEditViewProtocol)

    func deleteAll()

    func addAllToAlbum()
}

class SearchResultEditPresenter: ClipsListPresenter & ClipsListEditableContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: ClipsListEditableContainer

    var selectedClips: [Clip] = []

    var editableView: ClipsListEditableViewProtocol? {
        return self.internalView
    }

    // MARK: Internal

    weak var internalView: SearchResultEditViewProtocol?

    // MARK: - Lifecycle

    public init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }
}

extension SearchResultEditPresenter: SearchResultEditPresenterProtocol {
    // MARK: - SearchResultEditPresenterProtocol

    func set(view: SearchResultEditViewProtocol) {
        self.internalView = view
    }
}
