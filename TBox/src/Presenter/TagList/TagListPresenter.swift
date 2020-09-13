//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

protocol TagListViewProtocol: AnyObject {
    func reload()
    func showSearchReult(for clips: [Clip], withContext: SearchContext)
    func showErrorMessage(_ message: String)
    func endEditing()
}

class TagListPresenter {
    enum FailureContext {
        case readTag
        case addTag
        case searchClip
        case deleteTag
    }

    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private(set) var tags: [String] = []

    weak var view: TagListViewProtocol?

    // MARK: - Lifecycle

    init(storage: ClipStorageProtocol, logger: TBoxLoggable) {
        self.storage = storage
        self.logger = logger
    }

    // MARK: - Methods

    private static func resolveErrorMessage(for error: ClipStorageError, at context: FailureContext) -> String {
        let message: String = {
            switch context {
            case .readTag:
                return L10n.tagListViewErrorAtReadTags

            case .addTag:
                return L10n.tagListViewErrorAtAddTag

            case .deleteTag:
                return L10n.tagListViewErrorAtDeleteTag

            case .searchClip:
                return L10n.tagListViewErrorAtSearchClip
            }
        }()
        return message + "\n(\(error.makeErrorCode()))"
    }

    func reload() {
        guard let view = self.view else { return }

        switch self.storage.readAllTags() {
        case let .success(tags):
            self.tags = tags
            view.reload()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to read tags. (code: \(error.rawValue))"))
            view.showErrorMessage(Self.resolveErrorMessage(for: error, at: .readTag))
        }
    }

    func addTag(_ name: String) {
        guard let view = self.view else { return }

        switch self.storage.create(tagWithName: name) {
        case .success:
            self.reload()

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            view.showErrorMessage(Self.resolveErrorMessage(for: error, at: .addTag))
        }
    }

    func select(at index: Int) {
        guard self.tags.indices.contains(index) else { return }
        let tagName = self.tags[index]

        switch self.storage.searchClips(byTags: [tagName]) {
        case let .success(clips):
            view?.showSearchReult(for: clips, withContext: .tag(tagName: tagName))

        case let .failure(error):
            self.logger.write(ConsoleLog(level: .error, message: "Failed to search clips. (code: \(error.rawValue))"))
            view?.showErrorMessage(Self.resolveErrorMessage(for: error, at: .searchClip))
        }
    }

    func delete(at indices: [Int]) {
        let tags = indices.map { self.tags[$0] }
        tags.forEach { tag in
            switch self.storage.deleteTag(tag) {
            case let .failure(error):
                self.logger.write(ConsoleLog(level: .error, message: "Failed to delete tag. (code: \(error.rawValue))"))
                self.view?.showErrorMessage(Self.resolveErrorMessage(for: error, at: .deleteTag))

            default:
                self.tags.removeAll(where: { $0 == tag })
            }
        }
        view?.endEditing()
        view?.reload()
    }
}
