//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumViewProtocol: ClipsListViewProtocol {}

protocol AlbumPresenterProtocol: ClipsListPresenterProtocol & AddingClipsToAlbumPresenterDelegate {
    var album: Album { get }

    func set(view: AlbumViewProtocol)

    func deleteFromAlbum()

    func replaceAlbum(by album: Album)
}

class AlbumPresenter: ClipsListPresenter {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    var clips: [Clip] {
        return self.album.clips
    }

    var selectedClips: [Clip]

    var isEditing: Bool

    var storage: ClipStorageProtocol

    // MARK: AlbumPresenterProtocol

    var album: Album

    // MARK: Internal

    private weak var internalView: AlbumViewProtocol?

    // MARK: - Lifecycle

    init(album: Album, storage: ClipStorageProtocol) {
        self.album = album
        self.storage = storage
        self.selectedClips = []
        self.isEditing = false
    }
}

extension AlbumPresenter: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    func updateClips(to clips: [Clip]) {
        self.album = self.album.updatingClips(to: clips)
    }

    func set(view: AlbumViewProtocol) {
        self.internalView = view
    }

    func deleteFromAlbum() {
        switch self.storage.remove(clips: self.selectedClips.map { $0.url }, fromAlbum: self.album.id) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
        }

        let newClips: [Clip] = self.album.clips.compactMap { clip in
            if self.selectedClips.contains(where: { clip.url == $0.url }) { return nil }
            return clip
        }
        self.album = self.album.updatingClips(to: newClips)

        self.selectedClips = []
        self.internalView?.deselectAll()

        self.internalView?.reload()

        self.internalView?.endEditing()
    }

    func replaceAlbum(by album: Album) {
        self.album = album
        self.internalView?.reload()
    }
}
