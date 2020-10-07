//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagListViewProtocol: AnyObject {
    func apply(_ tags: [Tag])
    func search(with context: SearchContext)
    func showErrorMessage(_ message: String)
    func endEditing()
}

class TagListPresenter {
    private let storage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?
    private var tagListQuery: TagListQuery?

    weak var view: TagListViewProtocol?

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, queryService: ClipQueryServiceProtocol, logger: TBoxLoggable) {
        self.storage = storage
        self.queryService = queryService
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        switch self.queryService.queryAllTags() {
        case let .success(query):
            self.tagListQuery = query
            self.cancellable = query.tags
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] tags in
                    self?.view?.apply(tags)
                })

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtReadTags)\n\(error.makeErrorCode())")
        }
    }

    func addTag(_ name: String) {
        if case let .failure(error) = self.storage.create(tagWithName: name) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtAddTag)\n\(error.makeErrorCode())")
        }
    }

    func select(_ tag: Tag) {
        self.view?.search(with: .tag(tag))
    }

    func delete(_ tags: [Tag]) {
        if case let .failure(error) = self.storage.delete(tags) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtDeleteTag)\n\(error.makeErrorCode())")
            return
        }
        self.view?.endEditing()
    }
}
