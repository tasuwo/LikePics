//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TagListViewProtocol: AnyObject {
    func reload()
    func showSearchReult(for clips: [Clip], withContext: SearchContext)
    func showErrorMassage(_ message: String)
}

class TagListPresenter {
    private let storage: ClipStorageProtocol
    private(set) var tags: [String] = []
    weak var view: TagListViewProtocol?

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol) {
        self.storage = storage
    }

    // MARK: - Methods

    private static func resolveErrorMessage(_ error: Error) -> String {
        // TODO:
        return "TODO"
    }

    func reload() {
        guard let view = self.view else { return }

        switch self.storage.readAllTags() {
        case let .success(tags):
            self.tags = tags
            view.reload()

        case let .failure(error):
            view.showErrorMassage(Self.resolveErrorMessage(error))
        }
    }

    func select(at index: Int) {
        guard self.tags.indices.contains(index) else { return }
        let tagName = self.tags[index]

        switch self.storage.searchClips(byTags: [tagName]) {
        case let .success(clips):
            view?.showSearchReult(for: clips, withContext: .tag(tagName: tagName))

        case let .failure(error):
            view?.showErrorMassage(Self.resolveErrorMessage(error))
        }
    }
}
