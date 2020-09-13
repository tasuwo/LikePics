//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol TagListViewProtocol: AnyObject {
    func reload()
    func showSearchReult(for clips: [Clip], withContext: SearchContext)
    func showErrorMessage(_ message: String)
    func endEditing()
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
            view.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }

    func addTag(_ name: String) {
        guard let view = self.view else { return }

        switch self.storage.create(tagWithName: name) {
        case .success:
            self.reload()

        case let .failure(error):
            view.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }

    func select(at index: Int) {
        guard self.tags.indices.contains(index) else { return }
        let tagName = self.tags[index]

        switch self.storage.searchClips(byTags: [tagName]) {
        case let .success(clips):
            view?.showSearchReult(for: clips, withContext: .tag(tagName: tagName))

        case let .failure(error):
            view?.showErrorMessage(Self.resolveErrorMessage(error))
        }
    }

    func delete(at indices: [Int]) {
        let tags = indices.map { self.tags[$0] }
        tags.forEach { tag in
            switch self.storage.deleteTag(tag) {
            case let .failure(error):
                self.view?.showErrorMessage(Self.resolveErrorMessage(error))

            default:
                self.tags.removeAll(where: { $0 == tag })
            }
        }
        view?.endEditing()
        view?.reload()
    }
}
