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
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip] {
        return self.album.clips
    }

    // MARK: Internal

    private weak var internalView: AlbumViewProtocol?

    private var internalSelectedClip: Clip?

    private let internalAlbum: Album

    // MARK: - Lifecycle

    init(album: Album, storage: ClipStorageProtocol) {
        self.internalAlbum = album
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

    var selectedClip: Clip? {
        self.internalSelectedClip
    }

    func select(at index: Int) -> Clip? {
        guard self.clips.indices.contains(index) else { return nil }
        let clip = self.clips[index]
        self.internalSelectedClip = clip
        return clip
    }

    var album: Album {
        return self.internalAlbum
    }

    func set(view: AlbumViewProtocol) {
        self.internalView = view
    }
}
