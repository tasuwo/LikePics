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
    private let clipId: Clip.Identity
    private let storage: ClipStorageProtocol
    private let queryService: ClipQueryServiceProtocol
    private let logger: TBoxLoggable

    private var clipQuery: ClipQuery
    private var cancellable: AnyCancellable?

    private(set) var clip: Clip {
        didSet {
            self.view?.reloadPages()
        }
    }

    weak var view: ClipPreviewPageViewProtocol?

    // MARK: - Lifecycle

    init?(clipId: Clip.Identity,
          storage: ClipStorageProtocol,
          queryService: ClipQueryServiceProtocol,
          logger: TBoxLoggable)
    {
        self.clipId = clipId
        self.storage = storage
        self.queryService = queryService
        self.logger = logger

        switch queryService.queryClip(having: clipId) {
        case let .success(query):
            self.clipQuery = query
            self.clip = query.clip.value

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read clip for preview page. (code: \(error.rawValue))"))
            return nil
        }
    }

    // MARK: - Methods

    func setup() {
        self.cancellable = self.clipQuery
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

    func deleteClipItem(at index: Int) {
        guard self.clip.items.indices.contains(index) else { return }
        if case let .failure(error) = self.storage.delete(self.clip.items[index]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip item. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipItemPreviewViewErrorAtDeleteClipItem)\n\(error.makeErrorCode())")
        }
    }
}

extension ClipPreviewPagePresenter: ClipPreviewPageBarButtonItemsPresenterDataSource {
    // MARK: - ClipPreviewPageToolBarItemsPresenterDataSource

    func itemsCount(_ presenter: ClipPreviewPageBarButtonItemsPresenter) -> Int {
        return self.clip.items.count
    }
}
