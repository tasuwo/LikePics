//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol TopClipCollectionViewProtocol: AnyObject {
    func presentPreview(forClipId clipId: Clip.Identity, availability: @escaping (_ isAvailable: Bool) -> Void)
    func setEditing(_ editing: Bool)
    func showErrorMessage(_ message: String)
}

protocol TopClipCollectionPresenterProtocol {
    var clips: CurrentValueSubject<[Clip], Error> { get }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Error> { get }

    var previewingClip: Clip? { get }

    func viewDidAppear()

    func readImageIfExists(for clipItem: ClipItem) -> UIImage?
    func fetchImage(for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void)

    func setup(with view: TopClipCollectionViewProtocol)
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

class TopClipCollectionPresenter {
    private let query: ClipListQuery
    private let clipService: ClipCommandServiceProtocol
    private let cacheStorage: ThumbnailStorageProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var storage = Set<AnyCancellable>()

    private(set) var clips: CurrentValueSubject<[Clip], Error> = .init([])
    private(set) var selections: CurrentValueSubject<Set<Clip.Identity>, Error> = .init([])

    private var previewingClipId: Clip.Identity?

    var previewingClip: Clip? {
        guard let id = self.previewingClipId else { return nil }
        return self.clips.value.first(where: { $0.identity == id })
    }

    private var selectedClips: [Clip] {
        return self.selections.value
            .compactMap { selection in
                return self.clips.value.first(where: { selection == $0.identity })
            }
    }

    private var isEditing: Bool = false {
        didSet {
            self.deselectAll()
            self.view?.setEditing(self.isEditing)
        }
    }

    private weak var view: TopClipCollectionViewProtocol?

    // MARK: - Lifecycle

    init(query: ClipListQuery,
         clipService: ClipCommandServiceProtocol,
         cacheStorage: ThumbnailStorageProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clipService = clipService
        self.cacheStorage = cacheStorage
        self.settingStorage = settingStorage
        self.logger = logger
    }
}

extension TopClipCollectionPresenter: TopClipCollectionPresenterProtocol {
    // MARK: - TopClipCollectionPresenterProtocol

    func viewDidAppear() {
        self.previewingClipId = nil
    }

    func readImageIfExists(for clipItem: ClipItem) -> UIImage? {
        return self.cacheStorage.readThumbnailIfExists(for: clipItem)
    }

    func fetchImage(for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void) {
        self.cacheStorage.requestThumbnail(for: clipItem, completion: completion)
    }

    func setup(with view: TopClipCollectionViewProtocol) {
        self.view = view
        self.query.clips
            .catch { _ -> AnyPublisher<[Clip], Never> in
                return Just([Clip]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: """
                Unexpectedly finished observing at TopClipsView.
                """))
            }, receiveValue: { [weak self] clips, showHiddenItems in
                guard let self = self else { return }

                let newClips = clips
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })
                    .sorted(by: { $0.registeredDate > $1.registeredDate })
                self.clips.send(newClips)

                self.isEditing = false
                self.deselectAll()
            })
            .store(in: &self.storage)
    }

    func setEditing(_ editing: Bool) {
        self.isEditing = editing
    }

    func select(clipId: Clip.Identity) {
        if self.isEditing {
            self.selections.send(self.selections.value.union(Set([clipId])))
        } else {
            self.selections.send(Set([clipId]))
            self.view?.presentPreview(forClipId: clipId) { [weak self] isAvailable in
                guard isAvailable else { return }
                self?.previewingClipId = clipId
            }
        }
    }

    func selectAll() {
        guard self.isEditing else { return }
        self.selections.send(Set(self.clips.value.map { $0.identity }))
    }

    func deselect(clipId: Clip.Identity) {
        guard self.selections.value.contains(clipId) else { return }
        self.selections.send(self.selections.value.subtracting(Set([clipId])))
    }

    func deselectAll() {
        self.selections.send([])
    }

    func deleteSelectedClips() {
        if case let .failure(error) = self.clipService.deleteClips(having: self.selectedClips.ids) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClips)\n(\(error.makeErrorCode())")
        }
        self.deselectAll()
        self.isEditing = false
    }

    func hideSelectedClips() {
        if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to hide clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtHideClips)\n(\(error.makeErrorCode())")
        }
        self.deselectAll()
        self.isEditing = false
    }

    func unhideSelectedClips() {
        if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to unhide clips. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtUnhideClips)\n(\(error.makeErrorCode())")
        }
        self.deselectAll()
        self.isEditing = false
    }

    func addTagsToSelectedClips(_ tagIds: Set<Tag.Identity>) {
        if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byAddingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tags (\(tagIds.map({ $0.uuidString }).joined(separator: ", "))) to clips. (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddTagsToClips)\n(\(error.makeErrorCode())")
        }
        self.deselectAll()
        self.isEditing = false
    }

    func addSelectedClipsToAlbum(_ albumId: Album.Identity) {
        if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: Array(self.selections.value)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add clips to album having id \(albumId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipsToAlbum)\n(\(error.makeErrorCode())")
        }
        self.deselectAll()
        self.isEditing = false
    }

    func deleteClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipService.deleteClips(having: [id]) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to delete clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtDeleteClip)\n(\(error.makeErrorCode())")
        }
    }

    func hideClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: true) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to hide clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtHideClip)\n(\(error.makeErrorCode())")
        }
    }

    func unhideClip(having id: Clip.Identity) {
        if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: false) {
            self.logger.write(ConsoleLog(level: .error, message: "Failed to unhide clip having id \(id). (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtUnhideClip)\n(\(error.makeErrorCode())")
        }
    }

    func addTags(having tagIds: Set<Tag.Identity>, toClipHaving clipId: Clip.Identity) {
        if case let .failure(error) = self.clipService.updateClips(having: [clipId], byReplacingTagsHaving: Array(tagIds)) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to replace tags (\(tagIds.map({ $0.uuidString }).joined(separator: ",")) of clip having \(clipId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddTagsToClip)\n(\(error.makeErrorCode())")
        }
    }

    func addClip(having clipId: Clip.Identity, toAlbumHaving albumId: Album.Identity) {
        if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: [clipId]) {
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add clip having id \(clipId) to album having id \(albumId). (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.clipsListErrorAtAddClipToAlbum)\n(\(error.makeErrorCode())")
        }
    }
}

extension TopClipCollectionPresenter: ClipCollectionNavigationBarPresenterDataSource {
    // MARK: - ClipCollectionNavigationBarPresenterDataSource

    func clipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int {
        return self.clips.value.count
    }

    func selectedClipsCount(_ presenter: ClipCollectionNavigationBarPresenter) -> Int {
        return self.selections.value.count
    }
}

extension TopClipCollectionPresenter: ClipCollectionToolBarPresenterDataSource {
    // MARK: - ClipCollectionToolBarPresenterDataSource

    func selectedClipsCount(_ presenter: ClipCollectionToolBarPresenter) -> Int {
        return self.selections.value.count
    }
}
