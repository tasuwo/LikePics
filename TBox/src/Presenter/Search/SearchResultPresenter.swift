//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SearchResultViewProtocol: ClipsListViewProtocol {}

protocol SearchResultPresenterProtocol: ClipsListDisplayablePresenter {
    func set(view: SearchResultViewProtocol)
}

class SearchResultPresenter: ClipsListPresenter {
    // MARK: - Properties

    // MARK: ClipsListPresenter

    var view: ClipsListViewProtocol? {
        return self.internalView
    }

    let storage: ClipStorageProtocol

    var clips: [Clip]

    // MARK: Internal

    private weak var internalView: SearchResultViewProtocol?

    private var internalSelectedClip: Clip?

    // MARK: - Lifecycle

    init(clips: [Clip], storage: ClipStorageProtocol) {
        self.clips = clips
        self.storage = storage
    }

    static func resolveErrorMessage(_ error: ClipStorageError) -> String {
        // TODO: Error Handling
        return "問題が発生しました"
    }
}

extension SearchResultPresenter: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    var selectedClip: Clip? {
        self.internalSelectedClip
    }

    func select(at index: Int) -> Clip? {
        guard self.clips.indices.contains(index) else { return nil }
        let clip = self.clips[index]
        self.internalSelectedClip = clip
        return clip
    }

    func set(view: SearchResultViewProtocol) {
        self.internalView = view
    }
}
