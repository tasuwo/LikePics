//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipsListViewProtocol: AnyObject {
    func reload()

    func deselectAll()

    func endEditing()

    func presentPreviewView(for clip: Clip)

    func presentAlbumSelectionView(for clips: [Clip])

    func showErrorMassage(_ message: String)
}

protocol ClipsListPresenter: AnyObject {
    var view: ClipsListViewProtocol? { get }

    var clips: [Clip] { get }

    var selectedClips: [Clip] { get set }

    var isEditing: Bool { get set }

    var storage: ClipStorageProtocol { get }

    func updateClips(to clips: [Clip])

    static func resolveErrorMessage(_ error: ClipStorageError) -> String
}

extension ClipsListPresenter {
    static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO:
        return "問題が発生しました"
    }
}

extension ClipsListPresenter where Self: ClipsListPresenterProtocol {
    var selectedIndices: [Int] {
        return self.selectedClips.compactMap { selectedClip in
            self.clips.firstIndex(where: { $0.url == selectedClip.url })
        }
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        let nullableClipItem: ClipItem? = {
            switch layer {
            case .primary:
                return clip.primaryItem
            case .secondary:
                return clip.secondaryItem
            case .tertiary:
                return clip.tertiaryItem
            }
        }()
        guard let clipItem = nullableClipItem else { return nil }

        switch self.storage.read(imageDataOfUrl: clipItem.thumbnail.url, forClipOfUrl: clip.url) {
        case let .success(data):
            return data
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
            return nil
        }
    }

    func setEditing(_ editing: Bool) {
        if self.isEditing != editing {
            self.selectedClips = []
            self.view?.deselectAll()
        }
        self.isEditing = editing
    }

    func select(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        if self.isEditing {
            guard !self.selectedClips.contains(where: { $0.url == clip.url }) else {
                return
            }
            self.selectedClips.append(clip)
        } else {
            self.selectedClips = [clip]
            self.view?.presentPreviewView(for: clip)
        }
    }

    func deselect(at index: Int) {
        guard self.clips.indices.contains(index) else { return }
        let clip = self.clips[index]

        if self.isEditing {
            guard let index = self.selectedClips.firstIndex(where: { $0.url == clip.url }) else {
                return
            }
            self.selectedClips.remove(at: index)
        } else {
            self.selectedClips = []
            self.view?.deselectAll()
        }
    }

    func deleteAll() {
        switch self.storage.delete(clips: self.selectedClips) {
        case .success:
            // NOP
            break
        case let .failure(error):
            self.view?.showErrorMassage(Self.resolveErrorMessage(error))
        }

        let newClips: [Clip] = self.clips.compactMap { clip in
            if self.selectedClips.contains(where: { clip.url == $0.url }) { return nil }
            return clip
        }
        self.updateClips(to: newClips)

        self.selectedClips = []
        self.view?.deselectAll()

        self.view?.reload()
        self.view?.endEditing()
    }

    func addAllToAlbum() {
        self.view?.presentAlbumSelectionView(for: self.selectedClips)
    }
}

extension ClipsListPresenter where Self: AddingClipsToAlbumPresenterDelegate {
    // MARK: AddingClipsToAlbumPresenterDelegate

    func addingClipsToAlbumPresenter(_ presenter: AddingClipsToAlbumPresenter, didSucceededToAdding isSucceeded: Bool) {
        guard isSucceeded else { return }

        self.selectedClips = []
        self.view?.deselectAll()
        self.view?.endEditing()
    }
}
