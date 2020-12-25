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
    private let clipCommandService: ClipCommandServiceProtocol
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
         clipCommandService: ClipCommandServiceProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clip = query.clip.value
        self.itemId = itemId
        self.clipCommandService = clipCommandService
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
                    self?.view?.showErrorMessage(L10n.clipInformationErrorAtReadClip)
                }
            }, receiveValue: { [weak self] clip in
                self?.clip = clip
            })
    }

    func replaceTagsOfClip(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clip.identity], byReplacingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to replace tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(L10n.clipInformationErrorAtReplaceTags)
        }
    }

    func removeTagFromClip(_ tag: Tag) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clip.identity], byDeletingTagsHaving: [tag.identity]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tags. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(L10n.clipInformationErrorAtRemoveTags)
        }
    }

    func update(isHidden: Bool) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clip.identity], byHiding: isHidden) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to update. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(L10n.clipInformationErrorAtUpdateHidden)
        }
    }

    func update(siteUrl: URL?) {
        if case let .failure(error) = self.clipCommandService.updateClipItems(having: [self.itemId], byUpdatingSiteUrl: siteUrl) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to update. (code: \(error.rawValue))"))
            self.view?.showErrorMessage(L10n.clipInformationErrorAtUpdateSiteUrl)
        }
    }
}
