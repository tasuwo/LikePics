//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

struct TopClipsListEditPresenterProxy {
    private let presenter: TopClipsListEditPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: TopClipsListEditPresenterProtocol) {
        self.presenter = presenter
    }
}

extension TopClipsListEditPresenterProxy: TopClipsListEditPresenterProtocol {
    // MARK: - TopClipsListEditPresenterProtocol

    func set(view: TopClipsListEditViewProtocol) {
        self.presenter.set(view: view)
    }
}

extension TopClipsListEditPresenterProxy: ClipsListEditablePresenter {
    // MARK: - ClipsListDisplayablePresenter

    var clips: [Clip] {
        return self.presenter.clips
    }

    var selectedClips: [Clip] {
        return self.presenter.selectedClips
    }

    var selectedIndices: [Int] {
        return self.presenter.selectedIndices
    }

    func select(at index: Int) {
        self.presenter.select(at: index)
    }

    func deselect(at index: Int) {
        self.presenter.deselect(at: index)
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.presenter.getImageData(for: layer, in: clip)
    }
}
