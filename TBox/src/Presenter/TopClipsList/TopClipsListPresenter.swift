//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: ClipsListReloadableViewProtocol {}

protocol TopClipsListPresenterProtocol: ClipsListDisplayablePresenter {
    func set(view: TopClipsListViewProtocol)

    func reload()
}

class TopClipsListPresenter: ClipsListReloadablePresenter {
    weak var internalView: TopClipsListViewProtocol?

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    var reloadableView: ClipsListReloadableViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip] = []

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}

extension TopClipsListPresenter: TopClipsListPresenterProtocol {
    // MARK: - TopClipsListPresenterProtocol

    func set(view: TopClipsListViewProtocol) {
        self.internalView = view
    }

    func reload() {
        self.loadAllClips()
    }
}
