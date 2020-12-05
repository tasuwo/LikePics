//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol AlbumViewProtocol: AnyObject {
    func apply(_ clips: [Clip])
    func apply(selection: Set<Clip>)
    func apply(_ state: AlbumPresenter.State)
    func presentPreview(forClipId clipId: Clip.Identity, availability: @escaping (_ isAvailable: Bool) -> Void)
    func showErrorMessage(_ message: String)
}

protocol AlbumPresenterProtocol {
    var album: Album { get }
    var clips: [Clip] { get }
    var previewingClip: Clip? { get }

    func viewDidAppear()

    func readImageIfExists(for clipItem: ClipItem) -> UIImage?
    func fetchImage(for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void)

    func setup(with view: AlbumViewProtocol)
    func startEditing()
    func startReordering()
    func cancel()
    func select(clipId: Clip.Identity)
    func deselect(clipId: Clip.Identity)
    func selectAll()
    func deselectAll()
    func deleteSelectedClips()
    func hideSelectedClips()
    func unhideSelectedClips()
    func removeSelectedClipsFromAlbum()
    func addTagsToSelectedClips(_ tagIds: Set<Tag.Identity>)
    func addSelectedClipsToAlbum(_ albumId: Album.Identity)

    func deleteClip(having id: Clip.Identity)
    func removeFromAlbum(clipHaving id: Clip.Identity)
    func hideClip(having id: Clip.Identity)
    func unhideClip(having id: Clip.Identity)
    func addTags(having tagIds: Set<Tag.Identity>, toClipHaving clipId: Clip.Identity)
    func addClip(having clipId: Clip.Identity, toAlbumHaving albumId: Album.Identity)
    func reorderClips(_ clipIds: [Clip.Identity])
}

class AlbumPresenter {
    enum State {
        case `default`
        case selecting
        case reordering

        var isEditing: Bool {
            return self != .default
        }
    }

    private let query: AlbumQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let thumbnailStorage: ThumbnailStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var storage = Set<AnyCancellable>()

    private(set) var album: Album

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

    private var state: State = .default {
        didSet {
            self.selections = []
            self.view?.apply(self.state)
        }
    }

    private var isEditing: Bool {
        return self.state.isEditing
    }

    private weak var view: AlbumViewProtocol?

    // MARK: - Lifecycle

    init(query: AlbumQuery,
         clipCommandService: ClipCommandServiceProtocol,
         thumbnailStorage: ThumbnailStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.album = query.album.value
        self.clipCommandService = clipCommandService
        self.thumbnailStorage = thumbnailStorage
        self.settingStorage = settingStorage
        self.logger = logger
    }
}

extension AlbumPresenter: AlbumPresenterProtocol {
    // MARK: - AlbumPresenterProtocol

    func viewDidAppear() {
        self.previewingClipId = nil
    }

    func readImageIfExists(for clipItem: ClipItem) -> UIImage? {
        return self.thumbnailStorage.readThumbnailIfExists(for: clipItem)
    }

    func fetchImage(for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.thumbnailStorage.requestThumbnail(for: clipItem, completion: completion)
    }

    func setup(with view: AlbumViewProtocol) {
        self.view = view
        self.query.album
            .assertNoFailure() // TODO:
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: """
                Unexpectedly finished observing at AlbumView.
                """))
            }, receiveValue: { [weak self] album, showHiddenItems in
                guard let self = self else { return }

                self.album = album

                self.clips = album
                    .clips
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })

                let newClips = Set(self.clips.map { $0.identity })
                if !self.selections.isSubset(of: newClips) {
                    self.selections = self.selections.subtracting(self.selections.subtracting(newClips))
                }
            })
            .store(in: &self.storage)
    }

    func startEditing() {
        self.state = .selecting
    }

    func startReordering() {
        self.state = .reordering
    }

    func cancel() {
        self.state = .default
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
        self.state = .default
    }

    func hideSelectedClips() {
        if case let .failure(error) = self.clipCommandService.updateClips(having: self.selectedClips.ids, byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to hide clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtHideClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.state = .default
    }

    func unhideSelectedClips() {
        if case let .failure(error) = self.clipCommandService.updateClips(having: self.selectedClips.ids, byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to unhide clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtUnhideClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.state = .default
    }

    func removeSelectedClipsFromAlbum() {
        if case let .failure(error) = self.clipCommandService.updateAlbum(having: self.album.identity, byDeletingClipsHaving: self.selectedClips.ids) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to remove clips from album having id \(self.album.identity). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtRemoveClipsFromAlbum)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.state = .default
    }

    func addTagsToSelectedClips(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.clipCommandService.updateClips(having: self.selectedClips.ids, byAddingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tags (\(tagIds.map({ $0.uuidString }).joined(separator: ", "))) to clips. (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddTagsToClips)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.state = .default
    }

    func addSelectedClipsToAlbum(_ albumId: Album.Identity) {
        if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: Array(self.selections)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add clips to album having id \(albumId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipsToAlbum)\n(\(error.makeErrorCode())")
        }
        self.selections = []
        self.state = .default
    }

    func deleteClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipCommandService.deleteClips(having: [id]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClip)\n(\(error.makeErrorCode())")
        }
    }

    func removeFromAlbum(clipHaving id: Clip.Identity) {
        if case let .failure(error) = self.clipCommandService.updateAlbum(having: self.album.identity, byDeletingClipsHaving: [id]) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to remove clip from album having id \(self.album.identity). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtRemoveClipsFromAlbum)\n(\(error.makeErrorCode())")
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
            Failed to replace tags (\(tagIds.map({ $0.uuidString }).joined(separator: ",")) of clip \(clipId). (code: \(error.rawValue))
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

    func reorderClips(_ clipIds: [Clip.Identity]) {
        if case let .failure(error) = self.clipCommandService.updateAlbum(having: self.album.id, byReorderingClipsHaving: clipIds) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to reorder clips in album having id \(self.album.id). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipToAlbum)\n(\(error.makeErrorCode())")
        }
    }
}

extension AlbumPresenter: ClipCollectionNavigationBarPresenterDataSource {
    // MARK: - ClipCollectionNavigationBarPresenterDataSource

    func isReorderable(_ presenter: ClipCollectionNavigationBarPresenter) -> Bool {
        return true
    }

    func clipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int {
        return self.clips.count
    }

    func selectedClipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int {
        return self.selections.count
    }
}

extension AlbumPresenter: ClipsListToolBarItemsPresenterDataSouce {
    // MARK: - ClipsListToolBarItemsPresenterDataSouce

    func selectedClipsCount(_ presenter: ClipsListToolBarItemsPresenter) -> Int {
        return self.selections.count
    }
}
