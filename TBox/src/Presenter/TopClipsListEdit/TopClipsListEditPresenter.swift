//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListEditViewProtocol: ClipsListViewProtocol {}

protocol TopClipsListEditPresenterProtocol: ClipsListEditablePresenter {
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

    // MARK: TopClipsListEditPresenterProtocol

    var selectedClips: [Clip] = []

    // MARK: Internal

    weak var internalView: TopClipsListEditViewProtocol?

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

    func select(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        guard !self.selectedClips.contains(where: { $0.url == clip.url }) else {
            return
        }
        self.selectedClips.append(clip)
    }

    func deselect(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        guard let index = self.selectedClips.firstIndex(where: { $0.url == clip.url }) else {
            return
        }
        self.selectedClips.remove(at: index)
    }

    func set(view: TopClipsListEditViewProtocol) {
        self.internalView = view
    }
}
