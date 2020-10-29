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
        if case let .failure(error) = self.storage.deleteClips(having: [self.clip.identity]) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to delete clip having id \(self.clip.identity). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClip)\n\(error.makeErrorCode())")
        }
    }

    func removeClipItem(having itemId: ClipItem.Identity) {
        guard let item = self.clip.items.first(where: { $0.identity == itemId }) else { return }
        if case let .failure(error) = self.storage.deleteClipItem(having: item.identity) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to delete clip item having id \(itemId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtRemoveItemFromClip)\n\(error.makeErrorCode())")
        }
    }

    func addTagsToClip(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.storage.updateClips(having: [self.clip.identity], byAddingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tags (\(tagIds.joined(separator: ", "))) to clip. (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddTagsToClip)\n(\(error.makeErrorCode())")
        }
    }

    func addClipToAlbum(_ albumId: Album.Identity) {
        if case let .failure(error) = self.storage.updateAlbum(having: albumId, byAddingClipsHaving: [self.clip.identity]) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add clips to album having id \(albumId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipsToAlbum)\n(\(error.makeErrorCode())")
        }
    }
}

extension ClipPreviewPagePresenter: ClipPreviewPageBarButtonItemsPresenterDataSource {
    // MARK: - ClipPreviewPageToolBarItemsPresenterDataSource

    func itemsCount(_ presenter: ClipPreviewPageBarButtonItemsPresenter) -> Int {
        return self.clip.items.count
    }
}