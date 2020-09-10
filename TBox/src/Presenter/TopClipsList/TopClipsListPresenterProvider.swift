//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

struct TopClipsListPresenterProxy {
    private var presenter: TopClipsListPresenterProtocol

    var view: TopClipsListViewProtocol? {
        get {
            return self.presenter.view
        }
        set {
            self.presenter.view = newValue
        }
    }

    // MARK: - Lifecycle

    init(presenter: TopClipsListPresenterProtocol) {
        self.presenter = presenter
    }
}

extension TopClipsListPresenterProxy: TopClipsListPresenterProtocol {
    // MARK: - TopClipsListPresenterProtocol

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
