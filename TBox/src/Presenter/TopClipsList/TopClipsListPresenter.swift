//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: ClipsListReloadableViewProtocol {}

protocol TopClipsListPresenterProtocol: ClipsListPreviewablePresenter {
    func set(view: TopClipsListViewProtocol)

    func reload()
}

class TopClipsListPresenter: ClipsListReloadablePresenter {
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

    // MARK: Internal

    weak var internalView: TopClipsListViewProtocol?

    private var internalSelectedClip: Clip?

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

    var selectedClip: Clip? {
        self.internalSelectedClip
    }

    func select(at index: Int) -> Clip? {
        guard self.clips.indices.contains(index) else { return nil }
        let clip = self.clips[index]
        self.internalSelectedClip = clip
        return clip
    }

    func set(view: TopClipsListViewProtocol) {
        self.internalView = view
    }

    func reload() {
        self.loadAllClips()
    }
}
