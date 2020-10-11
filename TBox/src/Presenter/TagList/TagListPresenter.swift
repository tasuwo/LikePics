//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagListViewProtocol: AnyObject {
    func apply(_ tags: [Tag], isFiltered: Bool)
    func search(with context: SearchContext)
    func showErrorMessage(_ message: String)
    func endEditing()
}

class TagListPresenter {
    private let query: TagListQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?

    private let searchQuery: CurrentValueSubject<String, Error> = .init("")
    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag = Set<AnyCancellable>()

    weak var view: TagListViewProtocol?

    // MARK: - Lifecycle

    init(query: TagListQuery, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.query = query
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        self.query
            .tags
            .combineLatest(self.searchQuery)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: "Unexpectedly finished observing at TagSelectionView."))
            }, receiveValue: { [weak self] tags, searchQuery in
                guard let self = self else { return }

                self.searchStorage.updateCache(tags)
                let tags = self.searchStorage.resolveTags(byQuery: searchQuery)
                    .sorted(by: { $0.name < $1.name })

                self.view?.apply(tags, isFiltered: !searchQuery.isEmpty)
            })
            .store(in: &self.cancellableBag)
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
        if case let .failure(error) = self.storage.deleteTags(having: tags.map({ $0.identity })) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtDeleteTag)\n\(error.makeErrorCode())")
            return
        }
        self.view?.endEditing()
    }

    func updateTag(having id: Tag.Identity, nameTo name: String) {
        if case let .failure(error) = self.storage.updateTag(having: id, nameTo: name) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to rename tag. (code: \(error.rawValue))"))
            // TODO:
            self.view?.showErrorMessage("\(L10n.tagListViewErrorAtDeleteTag)\n\(error.makeErrorCode())")
            return
        }
    }

    func performQuery(_ query: String) {
        self.searchQuery.send(query)
    }
}
