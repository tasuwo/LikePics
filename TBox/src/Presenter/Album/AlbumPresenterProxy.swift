//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

class AlbumPresenterProxy {
    private let presenter: AlbumPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: AlbumPresenterProtocol) {
        self.presenter = presenter
    }
}

extension AlbumPresenterProxy: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    var album: Album {
        return self.presenter.album
    }

    func set(view: AlbumViewProtocol) {
        self.presenter.set(view: view)
    }

    func deleteFromAlbum() {
        self.presenter.deleteFromAlbum()
    }

    func replaceAlbum(by album: Album) {
        self.presenter.replaceAlbum(by: album)
    }

    // MARK: ClipsListPresenterProtocol

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
}

extension AlbumPresenterProxy: AddingClipsToAlbumPresenterDelegate {
    // MARK: AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        self.presenter.addingClipsToAlbumPresenter(presenter, didSucceededToAdding: isSucceeded)
    }
}
