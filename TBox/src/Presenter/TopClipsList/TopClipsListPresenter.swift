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
    private let settingsStorage: UserSettingsStorageProtocol
    private var clipsList: ClipsListProtocol
    weak var view: TopClipsListViewProtocol?

    // MARK: - Lifecycle

    init(clipsList: ClipsListProtocol, settingsStorage: UserSettingsStorageProtocol) {
        self.clipsList = clipsList
        self.settingsStorage = settingsStorage

        self.clipsList.set(delegate: self)
        self.settingsStorage.add(observer: self)
    }

    // MARK: - Methods

    func reload() {
        self.clipsList.loadAll()
    }

    func hidesAll() {
        self.clipsList.hidesAll()
    }

    func unhidesAll() {
        self.clipsList.unhidesAll()
    }

    func selectAll() {
        self.clipsList.selectAll()
    }

    func deselectAll() {
        self.clipsList.deselectAll()
    }

    func reload(at index: Int) {
        self.clipsList.reload(at: index)
    }

    deinit {
        self.settingsStorage.remove(observer: self)
    }
}

extension TopClipsListPresenter: ClipsListDelegate {
    // MARK: - ClipsListDelegate

    func clipsListProviding(_ list: ClipsListProtocol, didUpdateClipsTo clips: [Clip]) {
        DispatchQueue.main.async {
            self.view?.reloadList()
        }
    }

    func clipsListProviding(_ list: ClipsListProtocol, didUpdateSelectedIndicesTo indices: [Int]) {
        DispatchQueue.main.async {
            self.view?.applySelection(at: indices)
        }
    }

    func clipsListProviding(_ list: ClipsListProtocol, didUpdateEditingStateTo isEditing: Bool) {
        DispatchQueue.main.async {
            self.view?.applyEditing(isEditing)
        }
    }

    func clipsListProviding(_ list: ClipsListProtocol, didTapClip clip: Clip, at index: Int) {
        DispatchQueue.main.async {
            self.view?.presentPreviewView(for: clip)
        }
    }

    func clipsListProviding(_ list: ClipsListProtocol, failedToReadClipsWith error: ClipStorageError) {
        DispatchQueue.main.async {
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtReadClips)\n(\(error.makeErrorCode())")
        }
    }

    func clipsListProviding(_ list: ClipsListProtocol, failedToDeleteClipsWith error: ClipStorageError) {
        DispatchQueue.main.async {
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClips)\n(\(error.makeErrorCode())")
        }
    }

    func clipsListProviding(_ list: ClipsListProtocol, failedToGetImageDataWith error: ClipStorageError) {
        DispatchQueue.main.async {
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtGetImageData)\n(\(error.makeErrorCode())")
        }
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

extension TopClipsListPresenter: UserSettingsObserver {
    // MARK: - UserSettingsObserver

    func onUpdated(to settings: UserSettings) {
        self.clipsList.visibleHiddenClips = settings.showHiddenItems
    }
}

extension TopClipsListPresenter: ClipsListNavigationPresenterDataSource {}
extension TopClipsListPresenter: ClipsListToolBarItemsPresenterDataSouce {}
