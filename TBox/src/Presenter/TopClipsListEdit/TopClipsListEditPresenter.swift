//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListEditViewProtocol: ClipsListViewProtocol {}

protocol TopClipsListEditPresenterProtocol: ClipsListDisplayablePresenter {
    func set(view: TopClipsListEditViewProtocol)
}

class TopClipsListEditPresenter: ClipsListPresenter {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: Internal

    weak var internalView: TopClipsListEditViewProtocol?

    private var internalSelectedClip: Clip?

    // MARK: - Lifecycle

    public init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }

    // MARK: - Methods

    static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}

extension TopClipsListEditPresenter: TopClipsListEditPresenterProtocol {
    // MARK: - TopClipsListEditPresenterProtocol

    var selectedClip: Clip? {
        self.internalSelectedClip
    }

    func select(at index: Int) -> Clip? {
        guard self.clips.indices.contains(index) else { return nil }
        let clip = self.clips[index]
        self.internalSelectedClip = clip
        return clip
    }

    func set(view: TopClipsListEditViewProtocol) {
        self.internalView = view
    }
}
