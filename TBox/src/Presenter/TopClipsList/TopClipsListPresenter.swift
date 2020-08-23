//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: ClipsListViewProtocol {}

protocol TopClipsListPresenterProtocol: ClipsListDisplayablePresenter {
    func set(view: TopClipsListViewProtocol)

    func reload()
}

class TopClipsListPresenter: ClipsListPresenter {
    weak var internalView: TopClipsListViewProtocol?

    var view: ClipsListViewProtocol? {
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
