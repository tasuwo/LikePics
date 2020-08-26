//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListEditViewProtocol: ClipsListEditableViewProtocol {}

protocol TopClipsListEditPresenterProtocol: ClipsListEditablePresenter {
    func set(view: TopClipsListEditViewProtocol)

    func deleteAll()

    func addAllToAlbum()
}

class TopClipsListEditPresenter: ClipsListPresenter & ClipsListEditableContainer {
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

    weak var internalView: TopClipsListEditViewProtocol?

    // MARK: - Lifecycle

    public init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }
}

extension TopClipsListEditPresenter: TopClipsListEditPresenterProtocol {
    // MARK: - TopClipsListEditPresenterProtocol

    func set(view: TopClipsListEditViewProtocol) {
        self.internalView = view
    }
}
