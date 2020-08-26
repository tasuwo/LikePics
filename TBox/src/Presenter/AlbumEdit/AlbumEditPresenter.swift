//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumEditViewProtocol: AlbumEditableViewProtocol {}

protocol AlbumEditPresenterProtocol: AlbumEditablePresenter {
    func set(view: AlbumEditViewProtocol)
}

class AlbumEditPresenter: ClipsListPresenter & AlbumEditableContainer {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip] {
        return self.album.clips
    }

    // MARK: AlbumEditableContainer

    var album: Album

    var selectedClips: [Clip] = []

    var editableView: AlbumEditableViewProtocol? {
        return self.internalView
    }

    // MARK: Internal

    weak var internalView: AlbumEditViewProtocol?

    // MARK: - Lifecycle

    public init(album: Album, storage: ClipStorageProtocol) {
        self.album = album
        self.storage = storage
    }
}

extension AlbumEditPresenter: AlbumEditPresenterProtocol {
    // MARK: - AlbumEditPresenterProtocol

    func set(view: AlbumEditViewProtocol) {
        self.internalView = view
    }
}
