//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

class SearchResultPresenterProxy {
    private let presenter: SearchResultPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: SearchResultPresenterProtocol) {
        self.presenter = presenter
    }
}

extension SearchResultPresenterProxy: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    var clips: [Clip] {
        return self.presenter.clips
    }

    var selectedClips: [Clip] {
        return self.presenter.selectedClips
    }

    var selectedIndices: [Int] {
        return self.presenter.selectedIndices
    }

    var isEditing: Bool {
        return self.presenter.isEditing
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        self.presenter.getImageData(for: layer, in: clip)
    }

    func setEditing(_ editing: Bool) {
        self.presenter.setEditing(editing)
    }

    func select(at index: Int) {
        self.presenter.select(at: index)
    }

    func deselect(at index: Int) {
        self.presenter.deselect(at: index)
    }

    func deleteAll() {
        self.presenter.deleteAll()
    }

    func addAllToAlbum() {
        self.presenter.addAllToAlbum()
    }

    func set(view: SearchResultViewProtocol) {
        self.presenter.set(view: view)
    }

    func replaceClips(by clips: [Clip]) {
        self.presenter.replaceClips(by: clips)
    }
}

extension SearchResultPresenterProxy: AddingClipsToAlbumPresenterDelegate {
    // MARK: AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        self.presenter.addingClipsToAlbumPresenter(presenter, didSucceededToAdding: isSucceeded)
    }
}
