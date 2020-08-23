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
