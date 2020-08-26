//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListEditViewProtocol: ClipsListViewProtocol {
    func reload()

    func deselectAll()

    func presentAddingClipsToAlbumView(by clips: [Clip])

    func endEditing()
}

protocol TopClipsListEditPresenterProtocol: ClipsListEditablePresenter & AddingClipsToAlbumPresenterDelegate {
    func set(view: TopClipsListEditViewProtocol)

    func deleteAll()

    func addAllToAlbum()
}

class TopClipsListEditPresenter: ClipsListPresenter & SelectedClipsContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: SelectedClipsContainer

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
        self.internalView?.presentAddingClipsToAlbumView(by: self.selectedClips)
    }
}

extension TopClipsListEditPresenter: AddingClipsToAlbumPresenterDelegate {
    // MARK: - AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }

        self.selectedClips = []
        self.internalView?.deselectAll()

        self.internalView?.endEditing()
    }
}
