//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol AlbumEditableViewProtocol: ClipsListEditableViewProtocol {}

protocol AlbumEditablePresenter: ClipsListEditablePresenter & AddingClipsToAlbumPresenterDelegate {
    var album: Album { get }

    func deleteFromAlbum()
}

extension AlbumEditablePresenter where Self: ClipsListPresenter & AlbumEditableContainer {
    var selectedIndices: [Int] {
        return self.selectedClips.compactMap { selectedClip in
            self.clips.firstIndex(where: { $0.url == selectedClip.url })
        }
    }

    func select(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        guard !self.selectedClips.contains(where: { $0.url == clip.url }) else {
            return
        }
        self.selectedClips.append(clip)
    }

    func deselect(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        guard let index = self.selectedClips.firstIndex(where: { $0.url == clip.url }) else {
            return
        }
        self.selectedClips.remove(at: index)
    }

    func deleteAll() {
        switch self.storage.removeClips(ofUrls: self.selectedClips.map { $0.url }) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
        }

        let newClips = self.album.clips.filter { clip in
            self.selectedClips.contains(where: { clip.url != $0.url })
        }
        // TODO:
        // self.album = self.album.updatingClips(to: newClips)

        self.selectedClips = []
        self.editableView?.deselectAll()

        self.editableView?.reload()

        self.editableView?.endEditing()
    }

    func addAllToAlbum() {
        self.editableView?.presentAlbumSelectionView(for: self.selectedClips)
    }

    func deleteFromAlbum() {
        switch self.storage.remove(clips: self.selectedClips.map { $0.url }, fromAlbum: self.album.id) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
        }

        let newClips = self.album.clips.filter { clip in
            self.selectedClips.contains(where: { clip.url != $0.url })
        }
        // TODO:
        // self.album = self.album.updatingClips(to: newClips)

        self.selectedClips = []
        self.editableView?.deselectAll()

        self.editableView?.reload()

        self.editableView?.endEditing()
    }
}

extension AlbumEditablePresenter where Self: ClipsListPresenter & AlbumEditableContainer {
    // MARK: AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }

        self.selectedClips = []
        self.editableView?.deselectAll()

        self.editableView?.endEditing()
    }
}
