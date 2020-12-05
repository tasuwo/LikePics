//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol SearchResultViewProtocol: AnyObject {
    func apply(_ clips: [Clip])
    func apply(selection: Set<Clip>)
    func presentPreview(forClipId clipId: Clip.Identity, availability: @escaping (_ isAvailable: Bool) -> Void)
    func setEditing(_ editing: Bool)
    func showErrorMessage(_ message: String)
}

enum SearchContext {
    case keywords([String])
    case tag(Tag)
    case uncategorized

    var title: String {
        switch self {
        case let .keywords(value):
            return value.joined(separator: ", ")

        case let .tag(value):
            return value.name

        case .uncategorized:
            return L10n.searchResultTitleUncategorized
        }
    }
}

protocol SearchResultPresenterProtocol {
    var clips: [Clip] { get }
    var context: SearchContext { get }
    var previewingClip: Clip? { get }

    func viewDidAppear()

    func readImageIfExists(for clipItem: ClipItem) -> UIImage?
    func fetchImage(for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void)

    func setup(with view: SearchResultViewProtocol)
    func setEditing(_ editing: Bool)
    func select(clipId: Clip.Identity)
    func deselect(clipId: Clip.Identity)
    func selectAll()
    func deselectAll()
    func deleteSelectedClips()
    func hideSelectedClips()
    func unhideSelectedClips()
    func addTagsToSelectedClips(_ tagIds: Set<Tag.Identity>)
    func addSelectedClipsToAlbum(_ albumId: Album.Identity)

    func deleteClip(having id: Clip.Identity)
    func hideClip(having id: Clip.Identity)
    func unhideClip(having id: Clip.Identity)
    func addTags(having tagIds: Set<Tag.Identity>, toClipHaving clipId: Clip.Identity)
    func addClip(having clipId: Clip.Identity, toAlbumHaving albumId: Album.Identity)
}

class SearchResultPresenter {
    private var query: ClipListQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let cacheStorage: ThumbnailStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var storage = Set<AnyCancellable>()

    let context: SearchContext

    private(set) var clips: [Clip] = [] {
        didSet {
            self.view?.apply(clips)
        }
    }

    private var previewingClipId: Clip.Identity?

    var previewingClip: Clip? {
        guard let id = self.previewingClipId else { return nil }
        return self.clips.first(where: { $0.identity == id })
    }

    private var selectedClips: [Clip] {
        return self.selections
            .compactMap { selection in
                return self.clips.first(where: { selection == $0.identity })
            }
    }

    private var selections: Set<Clip.Identity> = .init() {
        didSet {
            self.view?.apply(selection: Set(self.selectedClips))
        }
    }

    private var isEditing: Bool = false {
        didSet {
            self.selections = []
            self.view?.setEditing(self.isEditing)
        }
    }

    private weak var view: SearchResultViewProtocol?

    // MARK: - Lifecycle

    init(context: SearchContext,
         query: ClipListQuery,
         clipCommandService: ClipCommandServiceProtocol,
         cacheStorage: ThumbnailStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.context = context
        self.query = query
        self.clipCommandService = clipCommandService
        self.cacheStorage = cacheStorage
        self.settingStorage = settingStorage
        self.logger = logger
    }
}

extension SearchResultPresenter: SearchResultPresenterProtocol {
    // MARK: - SearchResultPresenterProtocol

    func viewDidAppear() {
        self.previewingClipId = nil
    }

    func readImageIfExists(for clipItem: ClipItem) -> UIImage? {
        return self.cacheStorage.readThumbnailIfExists(for: clipItem)
    }

    func fetchImage(for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.cacheStorage.requestThumbnail(for: clipItem, completion: completion)
    }

    func setup(with view: SearchResultViewProtocol) {
        self.view = view
        self.query.clips
            .catch { _ -> AnyPublisher<[Clip], Never> in
                return Just([Clip]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: """
                Unexpectedly finished observing at SearchResultView.
                """))
            }, receiveValue: { [weak self] clips, showHiddenItems in
                guard let self = self else { return }

                self.clips = clips
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })
                    .sorted(by: { $0.registeredDate > $1.registeredDate })

                let newClips = Set(self.clips.map { $0.identity })
                if !self.selections.isSubset(of: newClips) {
                    self.selections = self.selections.subtracting(self.selections.subtracting(newClips))
                }
            })
            .store(in: &self.storage)
    }

    func setEditing(_ editing: Bool) {
        self.isEditing = editing
    }

    func select(clipId: Clip.Identity) {
        if self.isEditing {
            self.selections.insert(clipId)
        } else {
            self.selections = Set([clipId])
            self.view?.presentPreview(forClipId: clipId) { [weak self] isAvailable in
                guard isAvailable else { return }
                self?.previewingClipId = clipId
            }
        }
    }

    func selectAll() {
        guard self.isEditing else { return }
        self.selections = Set(self.clips.map { $0.identity })
    }

    func deselect(clipId: Clip.Identity) {
        guard self.selections.contains(clipId) else { return }
        self.selections.remove(clipId)
    }

    func deselectAll() {
        self.selections = []
    }

    func deleteSelectedClips() {
        if case let .failure(error) = self.clipCommandService.deleteClips(having: self.selectedClips.ids) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func hideSelectedClips() {
        if case let .failure(error) = self.clipCommandService.updateClips(having: self.selectedClips.ids, byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to hide clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtHideClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func unhideSelectedClips() {
        if case let .failure(error) = self.clipCommandService.updateClips(having: self.selectedClips.ids, byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to unhide clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtUnhideClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func addTagsToSelectedClips(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: self.selectedClips.ids, byAddingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tags (\(tagIds.map({ $0.uuidString }).joined(separator: ", "))) to clips. (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddTagsToClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func addSelectedClipsToAlbum(_ albumId: Album.Identity) {
        if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: Array(self.selections)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add clips to album having id \(albumId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipsToAlbum)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.isEditing = false
    }

    func deleteClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipCommandService.deleteClips(having: [id]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClip)\n(\(error.makeErrorCode())")
        }
    }

    func hideClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [id], byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to hide clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtHideClip)\n(\(error.makeErrorCode())")
        }
    }

    func unhideClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [id], byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to unhide clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtUnhideClip)\n(\(error.makeErrorCode())")
        }
    }

    func addTags(having tagIds: Set<Tag.Identity>, toClipHaving clipId: Clip.Identity) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: [clipId], byReplacingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to replace tags (\(tagIds.map({ $0.uuidString }).joined(separator: ",")) of clip having \(clipId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddTagsToClip)\n(\(error.makeErrorCode())")
        }
    }

    func addClip(having clipId: Clip.Identity, toAlbumHaving albumId: Album.Identity) {
        if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [clipId]) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add clip having id \(clipId) to album having id \(albumId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipToAlbum)\n(\(error.makeErrorCode())")
        }
    }
}

extension SearchResultPresenter: ClipCollectionNavigationBarPresenterDataSource {
    // MARK: - ClipCollectionNavigationBarPresenterDataSource

    func isReorderable(_ presenter: ClipCollectionNavigationBarPresenter) -> Bool {
        return false
    }

    func clipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int {
        return self.selections.count
    }
}

extension SearchResultPresenter: ClipsListToolBarItemsPresenterDataSouce {
    // MARK: - ClipsListToolBarItemsPresenterDataSouce

    func selectedClipsCount(_ presenter: ClipsListToolBarItemsPresenter) -> Int {
        return self.selections.count
    }
}
