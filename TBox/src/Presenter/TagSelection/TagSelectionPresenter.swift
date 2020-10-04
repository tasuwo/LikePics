//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagSelectionViewProtocol: AnyObject {
    func apply(_ tags: [Tag])
    func showErrorMessage(_ message: String)
    func close()
}

protocol TagSelectionPresenterDelegate: AnyObject {
    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTags tags: [Tag])
}

class TagSelectionPresenter {
    private let query: TagListQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    weak var delegate: TagSelectionPresenterDelegate?
    weak var view: TagSelectionViewProtocol?

    // MARK: - Lifecycle

    init(query: TagListQuery, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.query = query
        self.storage = storage
        self.logger = logger

        // TODO: 選択済みのタグは選択済みにすべきかどうか
    }

    // MARK: - Methods

    func setup() {
        self.query
            .tags
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at TagSelectionView."))
            }, receiveValue: { [weak self] tagQueries in
                self?.view?.apply(tagQueries.map({ $0.tag.value }))
            })
            .store(in: &self.cancellableBag)
    }

    func addTag(_ name: String) {
        if case let .failure(error) = self.storage.create(tagWithName: name) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtAddTag)\n\(error.makeErrorCode())")
        }
    }

    func select(_ tags: [Tag]) {
        self.delegate?.tagSelectionPresenter(self, didSelectTags: tags)
        self.view?.close()
    }
}
