//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipInformationViewProtocol: AnyObject {
    func reload()
    func close()
    func showErrorMessage(_ message: String)
}

class ClipInformationPresenter {
    let itemId: ClipItem.Identity

    private let query: ClipQuery
    private let storage: ClipStorageProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?

    private(set) var clip: Clip {
        didSet {
            self.view?.reload()
        }
    }

    weak var view: ClipInformationViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipQuery,
         itemId: ClipItem.Identity,
         storage: ClipStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clip = query.clip.value
        self.itemId = itemId
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
                    self?.view?.close()

                case let .failure(error):
                    self?.logger.write(ConsoleLog(level: .error, message: "Error occurred. (error: \(error.localizedDescription))"))
                    self?.view?.showErrorMessage("\(L10n.clipPreviewPageViewErrorAtReadClip)")
                }
            }, receiveValue: { [weak self] clip in
                self?.clip = clip
            })
    }

    func addTagsToClip(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.storage.update([self.clip], byAddingTags: tagIds) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
    }

    func removeTagFromClip(_ tag: Tag) {
        if case let .failure(error) = self.storage.update([self.clip], byDeletingTags: [tag]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.albumListViewErrorAtReadImageData)\n(\(error.makeErrorCode())")
        }
    }
}
