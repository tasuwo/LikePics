//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipPreviewPageViewProtocol: AnyObject {
    func reloadPages()
    func closePages()
    func showErrorMessage(_ message: String)
}

class ClipPreviewPagePresenter {
    private let query: ClipQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?

    private(set) var clip: Clip {
        didSet {
            self.view?.reloadPages()
        }
    }

    weak var view: ClipPreviewPageViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipQuery, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.query = query
        self.clip = query.clip.value
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    func setup() {
        self.cancellable = self.query
            .clip
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    self?.view?.closePages()

                case let .failure(error):
                    self?.logger.write(ConsoleLog(level: .error, message: "Error occurred. (error: \(error.localizedDescription))"))
                    self?.view?.showErrorMessage("\(L10n.clipPreviewPageViewErrorAtReadClip)")
                }
            }, receiveValue: { [weak self] clip in
                self?.clip = clip
            })
    }

    func deleteClip() {
        if case let .failure(error) = self.storage.delete([self.clip]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipItemPreviewViewErrorAtDeleteClip)\n\(error.makeErrorCode())")
        }
    }

    func deleteClipItem(having itemId: ClipItem.Identity) {
        guard let item = self.clip.items.first(where: { $0.identity == itemId }) else { return }
        if case let .failure(error) = self.storage.delete(item) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip item. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipItemPreviewViewErrorAtDeleteClipItem)\n\(error.makeErrorCode())")
        }
    }

    func addTagsToClip(_ tags: [Tag]) {
        if case let .failure(error) = self.storage.update([self.clip], byAddingTags: tags) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
    }
}

extension ClipPreviewPagePresenter: ClipPreviewPageBarButtonItemsPresenterDataSource {
    // MARK: - ClipPreviewPageToolBarItemsPresenterDataSource

    func itemsCount(_ presenter: ClipPreviewPageBarButtonItemsPresenter) -> Int {
        return self.clip.items.count
    }
}
