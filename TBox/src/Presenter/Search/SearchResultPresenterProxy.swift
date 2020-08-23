//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchResultPresenterProxy {
    private let presenter: SearchResultPresenterProtocol

    // MARK: - Lifecycle

    init(presenter: SearchResultPresenterProtocol) {
        self.presenter = presenter
    }
}

extension SearchResultPresenterProxy: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    func set(view: SearchResultViewProtocol) {
        self.presenter.set(view: view)
    }
}

extension SearchResultPresenterProxy: ClipsListDisplayablePresenter {
    // MARK: - ClipsListDisplayablePresenter

    var clips: [Clip] {
        return self.presenter.clips
    }

    func getImageData(for layer: ThumbnailLayer, in clip: Clip) -> Data? {
        return self.presenter.getImageData(for: layer, in: clip)
    }
}
