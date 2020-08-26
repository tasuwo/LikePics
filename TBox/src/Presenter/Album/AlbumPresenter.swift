//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumViewProtocol: ClipsListViewProtocol {
    func reload()
}

protocol AlbumPresenterProtocol: ClipsListPreviewablePresenter {
    var album: Album { get }

    func replaceAlbum(by album: Album)

    func set(view: AlbumViewProtocol)
}

class AlbumPresenter: ClipsListPresenter & ClipsListPreviewableContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip] {
        return self.album.clips
    }

    // MARK: ClipsListPreviewableContainer

    var selectedClip: Clip?

    // MARK: AlbumPresenterProtocol

    var album: Album

    // MARK: Internal

    private weak var internalView: AlbumViewProtocol?

    // MARK: - Lifecycle

    init(album: Album, storage: ClipStorageProtocol) {
        self.album = album
        self.storage = storage
    }
}

extension AlbumPresenter: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    func replaceAlbum(by album: Album) {
        self.album = album
        self.internalView?.reload()
    }

    func set(view: AlbumViewProtocol) {
        self.internalView = view
    }
}
