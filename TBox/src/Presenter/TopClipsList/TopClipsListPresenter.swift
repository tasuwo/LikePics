//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: ClipsListReloadableViewProtocol {}

protocol TopClipsListPresenterProtocol: ClipsListPreviewablePresenter {
    func set(view: TopClipsListViewProtocol)

    func replaceClips(by clips: [Clip])

    func reload()
}

class TopClipsListPresenter: ClipsListReloadablePresenter & ClipsListReloadableContainer & ClipsListPreviewableContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    var reloadableView: ClipsListReloadableViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip] = []

    // MARK: - ClipsListPreviewableContainer

    var selectedClip: Clip?

    // MARK: Internal

    weak var internalView: TopClipsListViewProtocol?

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
    }
}

extension TopClipsListPresenter: TopClipsListPresenterProtocol {
    // MARK: - TopClipsListPresenterProtocol

    func set(view: TopClipsListViewProtocol) {
        self.internalView = view
    }

    func replaceClips(by clips: [Clip]) {
        self.clips = clips
        self.reload()
    }

    func reload() {
        self.loadAllClips()
    }
}
