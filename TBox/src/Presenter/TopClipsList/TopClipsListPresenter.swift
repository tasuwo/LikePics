//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: AnyObject {
    func reloadList()
    func deselectAll()
    func setEditing(_ editing: Bool)
    func presentPreviewView(for clip: Clip)
    func showErrorMessage(_ message: String)
}

class TopClipsListPresenter {
    private var clipsList: ClipsListProviding

    weak var view: TopClipsListViewProtocol?

    // MARK: - Lifecycle

    init(clipsList: ClipsListProviding) {
        self.clipsList = clipsList
        self.clipsList.set(delegate: self)
    }
}

extension TopClipsListPresenter: ClipsListProvidingDelegate {
    // MARK: - ClipsListProvidingDelegate

    func clipsListProviding(_ provider: ClipsListProviding, didUpdateClipsTo clips: [Clip]) {
        self.view?.reloadList()
    }

    func clipsListProviding(_ provider: ClipsListProviding, didUpdateEditingStateTo isEditing: Bool) {
        self.view?.setEditing(isEditing)
    }

    func clipsListProviding(_ provider: ClipsListProviding, didUpdateSelectedIndices indices: [Int]) {
        // TODO:
        if indices.isEmpty {
            self.view?.deselectAll()
        }
    }

    func clipsListProviding(_ provider: ClipsListProviding, didTapClip clip: Clip, at index: Int) {
        self.view?.presentPreviewView(for: clip)
    }

    func clipsListProviding(_ provider: ClipsListProviding, failedToReadClipsWith error: ClipStorageError) {
        // TODO:
        self.view?.showErrorMessage("")
    }

    func clipsListProviding(_ provider: ClipsListProviding, failedToDeleteClipsWith error: ClipStorageError) {
        // TODO:
        self.view?.showErrorMessage("")
    }

    func clipsListProviding(_ provider: ClipsListProviding, failedToGetImageDataWith error: ClipStorageError) {
        // TODO:
        self.view?.showErrorMessage("")
    }
}

extension TopClipsListPresenter: ClipsListPresenterProtocol {
    // MARK: - ClipsListPresenterProtocol

    var clips: [Clip] {
        self.clipsList.clips
    }

    var selectedClips: [Clip] {
        self.clipsList.selectedClips
    }

    var selectedIndices: [Int] {
        self.clipsList.selectedIndices
    }

    var isEditing: Bool {
        self.clipsList.isEditing
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.clipsList.getImageData(for: layer, in: clip)
    }

    func reload() {
        self.clipsList.reload()
    }

    func setEditing(_ editing: Bool) {
        self.clipsList.setEditing(editing)
    }

    func select(at index: Int) {
        self.clipsList.select(at: index)
    }

    func deselect(at index: Int) {
        self.clipsList.deselect(at: index)
    }

    func deleteAll() {
        self.clipsList.deleteSelectedClips()
    }
}

extension TopClipsListPresenter: AddingClipsToAlbumPresenterDelegate {
    // MARK: - AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        // guard isSucceeded else { return }

        // self.selectedClips = []
        // self.view?.deselectAll()
        // self.view?.endEditing()
    }
}
