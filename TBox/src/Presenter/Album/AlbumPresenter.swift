//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumViewProtocol: AnyObject {
    func reloadList()
    func applySelection(at indices: [Int])
    func applyEditing(_ editing: Bool)
    func presentPreviewView(for clip: Clip)
    func showErrorMessage(_ message: String)
}

class AlbumPresenter {
    private var clipsList: ClipsListProtocol

    weak var view: AlbumViewProtocol?

    private let storage: ClipStorageProtocol

    private(set) var album: Album

    // MARK: - Lifecycle

    init(album: Album, clipsList: ClipsListProtocol, storage: ClipStorageProtocol) {
        self.album = album
        self.clipsList = clipsList
        self.storage = storage

        self.clipsList.set(delegate: self)
    }

    // MARK: - Methods

    func removeFromAlbum() {
        self.clipsList.removeSelectedClips(from: self.album)
    }
}

extension AlbumPresenter: ClipsListDelegate {
    // MARK: - ClipsListDelegate

    func clipsListProviding(_ list: ClipsListProtocol, didUpdateClipsTo clips: [Clip]) {
        self.view?.reloadList()
    }

    func clipsListProviding(_ list: ClipsListProtocol, didUpdateSelectedIndicesTo indices: [Int]) {
        self.view?.applySelection(at: indices)
    }

    func clipsListProviding(_ list: ClipsListProtocol, didUpdateEditingStateTo isEditing: Bool) {
        self.view?.applyEditing(isEditing)
    }

    func clipsListProviding(_ list: ClipsListProtocol, didTapClip clip: Clip, at index: Int) {
        self.view?.presentPreviewView(for: clip)
    }

    func clipsListProviding(_ list: ClipsListProtocol, failedToReadClipsWith error: ClipStorageError) {
        self.view?.showErrorMessage("\(L10n.clipsListErrorAtReadClips)\n(\(error.makeErrorCode())")
    }

    func clipsListProviding(_ list: ClipsListProtocol, failedToDeleteClipsWith error: ClipStorageError) {
        self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClips)\n(\(error.makeErrorCode())")
    }

    func clipsListProviding(_ list: ClipsListProtocol, failedToGetImageDataWith error: ClipStorageError) {
        self.view?.showErrorMessage("\(L10n.clipsListErrorAtGetImageData)\n(\(error.makeErrorCode())")
    }
}

extension AlbumPresenter: ClipsListPresenterProtocol {
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
