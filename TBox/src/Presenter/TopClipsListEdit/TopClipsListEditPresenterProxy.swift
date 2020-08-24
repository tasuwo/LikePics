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

extension TopClipsListEditPresenterProxy: ClipsListDisplayablePresenter {
    // MARK: - ClipsListDisplayablePresenter

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
