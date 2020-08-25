//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListEditViewProtocol: ClipsListViewProtocol {
    func reload()

    func deselectAll()

    func endEditing()
}

protocol TopClipsListEditPresenterProtocol: ClipsListEditablePresenter {
    func set(view: TopClipsListEditViewProtocol)

    func deleteAll()

    func addAllToAlbum()
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

    func deleteAll() {
        switch self.storage.removeClips(ofUrls: self.selectedClips.map { $0.url }) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
        }

        self.clips.removeAll(where: { clip in
            self.selectedClips.contains(where: { clip.url == $0.url })
        })

        self.selectedClips = []
        self.internalView?.deselectAll()

        self.internalView?.reload()

        self.internalView?.endEditing()
    }

    func addAllToAlbum() {
        print(#function)
    }
}
