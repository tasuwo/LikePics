//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListEditableViewProtocol: ClipsListViewProtocol {
    func reload()

    func deselectAll()

    func presentAlbumSelectionView(for clips: [Clip])

    func endEditing()
}

protocol ClipsListEditablePresenter: ClipsListDisplayablePresenter & AddingClipsToAlbumPresenterDelegate {
    var selectedClips: [Clip] { get }

    var selectedIndices: [Int] { get }

    func select(at index: Int)

    func deselect(at index: Int)

    func deleteAll()

    func addAllToAlbum()
}

extension ClipsListEditablePresenter where Self: ClipsListPresenter & ClipsListEditableContainer {
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

        self.clips.removeAll(where: { clip in
            self.selectedClips.contains(where: { clip.url == $0.url })
        })

        self.selectedClips = []
        self.editableView?.deselectAll()

        self.editableView?.reload()

        self.editableView?.endEditing()
    }

    func addAllToAlbum() {
        self.editableView?.presentAlbumSelectionView(for: self.selectedClips)
    }
}

extension ClipsListEditablePresenter where Self: ClipsListPresenter & ClipsListEditableContainer {
    // MARK: AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }

        self.selectedClips = []
        self.editableView?.deselectAll()

        self.editableView?.endEditing()
    }
}
