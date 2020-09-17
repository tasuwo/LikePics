//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: AnyObject {
    func reloadList()
    func applySelection(at indices: [Int])
    func applyEditing(_ editing: Bool)
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

    // MARK: - Methods

    func reload() {
        self.clipsList.loadAll()
    }
}

extension TopClipsListPresenter: ClipsListProvidingDelegate {
    // MARK: - ClipsListProvidingDelegate

    func clipsListProviding(_ provider: ClipsListProviding, didUpdateClipsTo clips: [Clip]) {
        self.view?.reloadList()
    }

    func clipsListProviding(_ provider: ClipsListProviding, didUpdateSelectedIndicesTo indices: [Int]) {
        self.view?.applySelection(at: indices)
    }

    func clipsListProviding(_ provider: ClipsListProviding, didUpdateEditingStateTo isEditing: Bool) {
        self.view?.applyEditing(isEditing)
    }

    func clipsListProviding(_ provider: ClipsListProviding, didTapClip clip: Clip, at index: Int) {
        self.view?.presentPreviewView(for: clip)
    }

    func clipsListProviding(_ provider: ClipsListProviding, failedToReadClipsWith error: ClipStorageError) {
        self.view?.showErrorMessage("\(L10n.topClipsListViewErrorAtReadClips)\n(\(error.makeErrorCode())")
    }

    func clipsListProviding(_ provider: ClipsListProviding, failedToDeleteClipsWith error: ClipStorageError) {
        self.view?.showErrorMessage("\(L10n.topClipsListViewErrorAtDeleteClips)\n(\(error.makeErrorCode())")
    }

    func clipsListProviding(_ provider: ClipsListProviding, failedToGetImageDataWith error: ClipStorageError) {
        self.view?.showErrorMessage("\(L10n.topClipsListViewErrorAtGetImageData)\n(\(error.makeErrorCode())")
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
