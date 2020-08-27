//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

class SearchResultEditPresenterProxy {
    private let presenter: SearchResultEditPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: SearchResultEditPresenterProtocol) {
        self.presenter = presenter
    }
}

extension SearchResultEditPresenterProxy: SearchResultEditPresenterProtocol {
    // MARK: - SearchResultEditPresenterProtocol

    func set(view: SearchResultEditViewProtocol) {
        self.presenter.set(view: view)
    }

    func deleteAll() {
        self.presenter.deleteAll()
    }

    func addAllToAlbum() {
        self.presenter.addAllToAlbum()
    }

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        self.presenter.addingClipsToAlbumPresenter(presenter, didSucceededToAdding: isSucceeded)
    }
}

extension SearchResultEditPresenterProxy: ClipsListEditablePresenter {
    // MARK: - ClipsListDisplayablePresenter

    var clips: [Clip] {
        return self.presenter.clips
    }

    var selectedClips: [Clip] {
        return self.presenter.selectedClips
    }

    var selectedIndices: [Int] {
        return self.presenter.selectedIndices
    }

    func select(at index: Int) {
        self.presenter.select(at: index)
    }

    func deselect(at index: Int) {
        self.presenter.deselect(at: index)
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.presenter.getImageData(for: layer, in: clip)
    }
}
