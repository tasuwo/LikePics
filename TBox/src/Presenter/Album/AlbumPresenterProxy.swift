//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

struct AlbumPresenterProxy {
    private let presenter: AlbumPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: AlbumPresenterProtocol) {
        self.presenter = presenter
    }
}

extension AlbumPresenterProxy: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    var album: Album {
        self.presenter.album
    }

    func replaceAlbum(by album: Album) {
        self.presenter.replaceAlbum(by: album)
    }

    func set(view: AlbumViewProtocol) {
        self.presenter.set(view: view)
    }
}

extension AlbumPresenterProxy: ClipsListPreviewablePresenter {
    // MARK: - ClipsListDisplayablePresenter

    var clips: [Clip] {
        return self.presenter.clips
    }

    var selectedClip: Clip? {
        return self.presenter.selectedClip
    }

    var selectedIndex: Int? {
        return self.presenter.selectedIndex
    }

    func select(at index: Int) -> Clip? {
        return self.presenter.select(at: index)
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.presenter.getImageData(for: layer, in: clip)
    }
}
