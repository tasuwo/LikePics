//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol ClipPreviewPageViewProtocol: AnyObject {
    func reloadPages()

    func closePages()

    func showErrorMessage(_ message: String)
}

class ClipPreviewPagePresenter {
    enum FailureContext {
        case reload
        case deleteClip
        case deleteClipItem
    }

    weak var view: ClipPreviewPageViewProtocol?

    private let clipUrl: URL
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private(set) var clip: Clip

    // MARK: - Lifecycle

    init(clip: Clip, storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.clip = clip
        self.clipUrl = clip.url
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    private static func resolveErrorMessage(error: ClipStorageError, context: FailureContext) -> String {
        let message: String = {
            switch context {
            case .reload:
                return L10n.clipPreviewPageViewErrorAtReadClip

            case .deleteClip:
                return L10n.clipItemPreviewViewErrorAtDeleteClip

            case .deleteClipItem:
                return L10n.clipItemPreviewViewErrorAtDeleteClipItem
            }
        }()
        return message + "\n(\(error.makeErrorCode()))"
    }

    func reload() {
        switch self.storage.readClip(having: self.clipUrl) {
        case let .success(clip):
            self.clip = clip
            self.view?.reloadPages()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read clip. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .reload))
        }
    }

    func deleteClip() {
        switch self.storage.delete(self.clip) {
        case .success:
            self.view?.closePages()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .deleteClip))
        }
    }

    func deleteClipItem(at index: Int) {
        guard self.clip.items.indices.contains(index) else { return }
        switch self.storage.delete(self.clip.items[index]) {
        case .success:
            self.clip = self.clip.removedItem(at: index)
            self.view?.reloadPages()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip item. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(Self.resolveErrorMessage(error: error, context: .deleteClipItem))
        }
    }

    func onUpdatedClip(byUpdatingTags tags: [String]) {
        self.clip = self.clip.updating(tags: tags)
    }
}

extension ClipPreviewPagePresenter: ClipPreviewPageBarButtonItemsPresenterDataSource {
    // MARK: - ClipPreviewPageToolBarItemsPresenterDataSource

    func itemsCount(_ presenter: ClipPreviewPageBarButtonItemsPresenter) -> Int {
        return self.clip.items.count
    }
}
