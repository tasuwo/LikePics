//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagListViewProtocol: AnyObject {
    func apply(_ tags: [Tag])
    func showSearchReult(for clips: [Clip], withContext: SearchContext)
    func showErrorMessage(_ message: String)
    func endEditing()
}

class TagListPresenter {
    private var cancellable: AnyCancellable?
    private var tagListQuery: TagListQuery? {
        didSet {
            self.cancellable = self.tagListQuery?.tags
                .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] tagQueries in
                    self?.view?.apply(tagQueries.map({ $0.tag.value }))
                })
        }
    }

    private let storage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

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
        switch self.storage.searchClips(byTags: [tag.name]) {
        case let .success(clips):
            self.view?.showSearchReult(for: clips, withContext: .tag(tagName: tag.name))

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to search clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtSearchClip)\n\(error.makeErrorCode())")
        }
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
