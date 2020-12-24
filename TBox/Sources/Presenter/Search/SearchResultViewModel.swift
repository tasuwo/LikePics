//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol SearchResultViewModelInputs {
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }

    var viewDidAppear: PassthroughSubject<Void, Never> { get }

    var select: PassthroughSubject<Clip.Identity, Never> { get }
    var deselect: PassthroughSubject<Clip.Identity, Never> { get }
    var selectAll: PassthroughSubject<Void, Never> { get }
    var deselectAll: PassthroughSubject<Void, Never> { get }

    var deleteSelections: PassthroughSubject<Void, Never> { get }
    var hideSelections: PassthroughSubject<Void, Never> { get }
    var unhideSelections: PassthroughSubject<Void, Never> { get }
    var addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> { get }
    var addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> { get }

    var delete: PassthroughSubject<Clip.Identity, Never> { get }
    var hide: PassthroughSubject<Clip.Identity, Never> { get }
    var unhide: PassthroughSubject<Clip.Identity, Never> { get }
    var addTags: PassthroughSubject<(having: Set<Tag.Identity>, to: Clip.Identity), Never> { get }
    var addToAlbum: PassthroughSubject<(having: Album.Identity, Clip.Identity), Never> { get }
    var share: PassthroughSubject<Clip.Identity, Never> { get }
}

protocol SearchResultViewModelOutputs {
    var clips: CurrentValueSubject<[Clip], Never> { get }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { get }
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }
    var presentPreview: PassthroughSubject<(Clip.Identity, (_ isSucceeded: Bool) -> Void), Never> { get }
    var presentActivityController: PassthroughSubject<[Data], Never> { get }
    var previewingClip: Clip? { get }
    var title: CurrentValueSubject<String, Never> { get }
    var emptyMessage: CurrentValueSubject<String, Never> { get }
}

protocol SearchResultViewModelType {
    var inputs: SearchResultViewModelInputs { get }
    var outputs: SearchResultViewModelOutputs { get }
}

class SearchResultViewModel: SearchResultViewModelType,
    SearchResultViewModelInputs,
    SearchResultViewModelOutputs
{
    // MARK: - Properties

    // MARK: SearchResultViewModelType

    var inputs: SearchResultViewModelInputs { self }
    var outputs: SearchResultViewModelOutputs { self }

    // MARK: SearchResultViewModelInputs

    let viewDidAppear: PassthroughSubject<Void, Never> = .init()

    let select: PassthroughSubject<Clip.Identity, Never> = .init()
    let deselect: PassthroughSubject<Clip.Identity, Never> = .init()
    let selectAll: PassthroughSubject<Void, Never> = .init()
    let deselectAll: PassthroughSubject<Void, Never> = .init()

    let deleteSelections: PassthroughSubject<Void, Never> = .init()
    let hideSelections: PassthroughSubject<Void, Never> = .init()
    let unhideSelections: PassthroughSubject<Void, Never> = .init()
    let addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> = .init()
    let addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> = .init()

    let delete: PassthroughSubject<Clip.Identity, Never> = .init()
    let hide: PassthroughSubject<Clip.Identity, Never> = .init()
    let unhide: PassthroughSubject<Clip.Identity, Never> = .init()
    let addTags: PassthroughSubject<(having: Set<Tag.Identity>, to: Clip.Identity), Never> = .init()
    let addToAlbum: PassthroughSubject<(having: Album.Identity, Clip.Identity), Never> = .init()
    let share: PassthroughSubject<Clip.Identity, Never> = .init()

    // MARK: SearchResultViewModelOutputs

    let clips: CurrentValueSubject<[Clip], Never> = .init([])
    let selections: CurrentValueSubject<Set<Clip.Identity>, Never> = .init([])
    let operation: CurrentValueSubject<ClipCollection.Operation, Never> = .init(.none)
    let errorMessage: PassthroughSubject<String, Never> = .init()
    let presentPreview: PassthroughSubject<(Clip.Identity, (_ isSucceeded: Bool) -> Void), Never> = .init()
    let title: CurrentValueSubject<String, Never> = .init("")
    let emptyMessage: CurrentValueSubject<String, Never> = .init("")
    let presentActivityController: PassthroughSubject<[Data], Never> = .init()

    var previewingClip: Clip? {
        guard let id = self.previewingClipId else { return nil }
        return self.clips.value.first(where: { $0.identity == id })
    }

    // MARK: Privates

    private let context: ClipCollection.SearchContext
    private let query: ClipListQuery
    private let clipService: ClipCommandServiceProtocol
    private let imageQueryService: NewImageQueryServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()
    private var previewingClipId: Clip.Identity?

    private var selectedClips: [Clip] {
        return self.selections.value
            .compactMap { selection in
                return self.clips.value.first(where: { selection == $0.identity })
            }
    }

    // MARK: - Lifecycle

    init(context: ClipCollection.SearchContext,
         query: ClipListQuery,
         clipService: ClipCommandServiceProtocol,
         imageQueryService: NewImageQueryServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.context = context
        self.query = query
        self.clipService = clipService
        self.imageQueryService = imageQueryService
        self.settingStorage = settingStorage
        self.logger = logger

        self.bind()
    }
}

extension SearchResultViewModel {
    // MARK: - Binding

    private func bind() {
        self.bindOutputs()
        self.bindInputs()
    }

    private func bindOutputs() {
        self.query.clips
            .catch { _ -> AnyPublisher<[Clip], Never> in
                return Just([Clip]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: """
                Unexpectedly finished observing at SearchResultView.
                """))
            } receiveValue: { [weak self] clips, showHiddenItems in
                guard let self = self else { return }

                let newClips = clips
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })
                    .sorted(by: { $0.registeredDate > $1.registeredDate })
                self.clips.send(newClips)

                // 余分な選択を除外する
                let newClipIds = Set(self.clips.value.map { $0.identity })
                if self.selections.value.isSubset(of: newClipIds) == false {
                    self.selections.send(self.selections.value.subtracting(self.selections.value.subtracting(newClipIds)))
                }
            }
            .store(in: &self.cancellableBag)

        self.operation
            .sink { [weak self] _ in self?.deselectAll.send(()) }
            .store(in: &self.cancellableBag)

        self.title.send(self.context.label)

        self.emptyMessage.send({
            switch self.context {
            case let .keywords(keywords):
                return L10n.searchResultForKeywordsEmptyTitle(keywords.joined(separator: " "))

            case let .tag(.categorized(tag)):
                return L10n.searchResultForTagEmptyTitle(tag.name)

            case .tag(.uncategorized):
                return L10n.searchResultForUncategorizedEmptyTitle
            }
        }())
    }

    private func bindInputs() {
        self.viewDidAppear
            .sink { [weak self] _ in self?.previewingClipId = nil }
            .store(in: &self.cancellableBag)

        self.select
            .sink { [weak self] clipId in
                guard let self = self else { return }
                if self.operation.value.isEditing {
                    self.selections.send(self.selections.value.union(Set([clipId])))
                } else {
                    self.selections.send(Set([clipId]))
                    self.presentPreview.send((clipId, { isSucceeded in
                        guard isSucceeded else { return }
                        self.previewingClipId = clipId
                    }))
                }
            }
            .store(in: &self.cancellableBag)

        self.bindSelectOperations()
        self.bindClipOperations()
    }

    private func bindSelectOperations() {
        self.selectAll
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard self.operation.value.isEditing else { return }
                self.selections.send(Set(self.clips.value.map { $0.identity }))
            }
            .store(in: &self.cancellableBag)

        self.deselect
            .sink { [weak self] clipId in
                guard let self = self else { return }
                guard self.selections.value.contains(clipId) else { return }
                self.selections.send(self.selections.value.subtracting(Set([clipId])))
            }
            .store(in: &self.cancellableBag)

        self.deselectAll
            .sink { [weak self] _ in self?.selections.send([]) }
            .store(in: &self.cancellableBag)

        self.deleteSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.deleteClips(having: self.selectedClips.ids) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clips. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtDeleteClips)\n(\(error.makeErrorCode()))")
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.hideSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to hide clips. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtHideClips)\n(\(error.makeErrorCode()))")
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.unhideSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to unhide clips. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtUnhideClips)\n(\(error.makeErrorCode()))")
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.addTagsToSelections
            .sink { [weak self] tagIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byAddingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tags (\(tagIds.map({ $0.uuidString }).joined(separator: ", "))) to clips. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtAddTagsToClips)\n(\(error.makeErrorCode()))")
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.addSelectionsToAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: Array(self.selections.value)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add clips to album having id \(albumId). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtAddClipsToAlbum)\n(\(error.makeErrorCode()))")
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)
    }

    private func bindClipOperations() {
        self.delete
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.deleteClips(having: [id]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete clip having id \(id). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtDeleteClip)\n(\(error.makeErrorCode()))")
                }
            }
            .store(in: &self.cancellableBag)

        self.hide
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to hide clip having id \(id). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtHideClip)\n(\(error.makeErrorCode()))")
                }
            }
            .store(in: &self.cancellableBag)

        self.unhide
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to unhide clip having id \(id). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtUnhideClip)\n(\(error.makeErrorCode()))")
                }
            }
            .store(in: &self.cancellableBag)

        self.addTags
            .sink { [weak self] tagIds, clipId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [clipId], byReplacingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to replace tags (\(tagIds.map({ $0.uuidString }).joined(separator: ",")) of clip having \(clipId). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtAddTagsToClip)\n(\(error.makeErrorCode()))")
                }
            }
            .store(in: &self.cancellableBag)

        self.addToAlbum
            .sink { [weak self] albumId, clipId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: [clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add clip having id \(clipId) to album having id \(albumId). (code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipsListErrorAtAddClipToAlbum)\n(\(error.makeErrorCode()))")
                }
            }
            .store(in: &self.cancellableBag)

        self.share
            .receive(on: DispatchQueue.global())
            .sink { [weak self] clipId in
                guard let clip = self?.clips.value.first(where: { $0.id == clipId }) else {
                    self?.errorMessage.send(L10n.clipsListErrorAtShare)
                    return
                }
                do {
                    let images = try clip.items
                        .map { $0.imageId }
                        .compactMap { try self?.imageQueryService.read(having: $0) }
                    self?.presentActivityController.send(images)
                } catch {
                    self?.errorMessage.send(L10n.clipsListErrorAtShare)
                }
            }
            .store(in: &self.cancellableBag)
    }
}
