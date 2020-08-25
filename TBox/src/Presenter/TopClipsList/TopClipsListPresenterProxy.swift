//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

struct TopClipsListPresenterProxy {
    private let presenter: TopClipsListPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: TopClipsListPresenterProtocol) {
        self.presenter = presenter
    }
}

extension TopClipsListPresenterProxy: TopClipsListPresenterProtocol {
    // MARK: - TopClipsListPresenterProtocol

    func set(view: TopClipsListViewProtocol) {
        self.presenter.set(view: view)
    }

    func replaceClips(by clips: [Clip]) {
        self.presenter.replaceClips(by: clips)
    }

    func reload() {
        self.presenter.reload()
    }
}

extension TopClipsListPresenterProxy: ClipsListPreviewablePresenter {
    // MARK: - ClipsListPreviewablePresenter

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
