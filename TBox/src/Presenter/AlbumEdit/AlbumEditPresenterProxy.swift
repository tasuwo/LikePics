//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

class AlbumEditPresenterProxy {
    private let presenter: AlbumEditPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: AlbumEditPresenterProtocol) {
        self.presenter = presenter
    }
}

extension AlbumEditPresenterProxy: AlbumEditPresenterProtocol {
    // MARK: - AlbumEditPresenterProtocol

    var album: Album {
        return self.presenter.album
    }

    func set(view: AlbumEditViewProtocol) {
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

    func deleteFromAlbum() {
        self.presenter.deleteFromAlbum()
    }
}

extension AlbumEditPresenterProxy: ClipsListEditablePresenter {
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
