//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumViewProtocol: ClipsListViewProtocol {}

protocol AlbumPresenterProtocol: ClipsListDisplayablePresenter {
    var album: Album { get }

    func set(view: AlbumViewProtocol)
}

class AlbumPresenter: ClipsListPresenter {
    weak var internalView: AlbumViewProtocol?

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip] {
        return self.album.clips
    }

    let album: Album

    // MARK: - Lifecycle

    init(album: Album, storage: ClipStorageProtocol) {
        self.album = album
        self.storage = storage
    }

    // MARK: - Methods

    static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}

extension AlbumPresenter: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    func set(view: AlbumViewProtocol) {
        self.internalView = view
    }
}
