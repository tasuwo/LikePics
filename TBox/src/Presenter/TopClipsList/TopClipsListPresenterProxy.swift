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

    func reload() {
        self.presenter.reload()
    }
}

extension TopClipsListPresenterProxy: ClipsListDisplayablePresenter {
    // MARK: - ClipsListDisplayablePresenter

    var clips: [Clip] {
        return self.presenter.clips
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.presenter.getImageData(for: layer, in: clip)
    }
}
