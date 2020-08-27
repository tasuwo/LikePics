//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TopClipsListViewProtocol: NewClipsListViewProtocol {
    func startLoading()

    func endLoading()
}

protocol TopClipsListPresenterProtocol: ClipsListPresenterProtocol & AddingClipsToAlbumPresenterDelegate {
    func set(view: TopClipsListViewProtocol)

    func replaceClips(by clips: [Clip])

    func reload()
}

class TopClipsListPresenter: NewClipsListPresenter {
    // MARK: - Properties

    // MARK: ClipsListPresenterProtocol

    var clips: [Clip]

    var selectedClips: [Clip]

    var isEditing: Bool

    // MARK: NewClipsListPresenter

    var view: NewClipsListViewProtocol? {
        return self.internalView
    }

    var storage: ClipStorageProtocol

    // MARK: Internal

    private weak var internalView: TopClipsListViewProtocol?

    // MARK: - Lifecycle

    public init(storage: ClipStorageProtocol) {
        self.storage = storage
        self.isEditing = false
        self.clips = []
        self.selectedClips = []
    }
}

extension TopClipsListPresenter: TopClipsListPresenterProtocol {
    // MARK: - TopClipsListPresenterProtocol

    func set(view: TopClipsListViewProtocol) {
        self.internalView = view
    }

    func updateClips(to clips: [Clip]) {
        self.clips = clips
    }

    func replaceClips(by clips: [Clip]) {
        self.clips = clips
        self.reload()
    }

    func reload() {
        guard let view = self.internalView else { return }

        view.startLoading()
        switch self.storage.readAllClips() {
        case let .success(clips):
            self.clips = clips.sorted(by: { $0.registeredDate > $1.registeredDate })
            view.reload()
        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
        view.endLoading()
    }
}
