//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipCollectionViewModelType {
    var inputs: ClipCollectionViewModelInputs { get }
    var outputs: ClipCollectionViewModelOutputs { get }
}

protocol ClipCollectionViewModelInputs {
    // MARK: State

    var operationRequested: PassthroughSubject<ClipCollection.Operation, Never> { get }
    var clipsFetched: PassthroughSubject<[Clip], Never> { get }
    var dismissedPreview: PassthroughSubject<Void, Never> { get }

    // MARK: Selection

    var select: PassthroughSubject<Clip.Identity, Never> { get }
    var deselect: PassthroughSubject<Clip.Identity, Never> { get }
    var selectAll: PassthroughSubject<Void, Never> { get }
    var deselectAll: PassthroughSubject<Void, Never> { get }

    // MARK: Actions for Selection

    var deleteSelections: PassthroughSubject<Void, Never> { get }
    var hideSelections: PassthroughSubject<Void, Never> { get }
    var revealSelections: PassthroughSubject<Void, Never> { get }
    var addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> { get }
    var addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var mergeSelections: PassthroughSubject<Void, Never> { get }
    var shareSelections: PassthroughSubject<Void, Never> { get }

    // MARK: Actions for Single Clip

    var delete: PassthroughSubject<Clip.Identity, Never> { get }
    var hide: PassthroughSubject<Clip.Identity, Never> { get }
    var reveal: PassthroughSubject<Clip.Identity, Never> { get }
    var purge: PassthroughSubject<Clip.Identity, Never> { get }
    var replaceTags: PassthroughSubject<ClipCollection.TagsReplacingRequest, Never> { get }
    var addToAlbum: PassthroughSubject<ClipCollection.AddingToAlbumRequest, Never> { get }
    var share: PassthroughSubject<Clip.Identity, Never> { get }
}

protocol ClipCollectionViewModelOutputs {
    // MARK: State

    var clips: AnyPublisher<[Clip], Never> { get }
    var selectedClips: AnyPublisher<[Clip], Never> { get }
    var selections: Set<Clip.Identity> { get }
    var previewingClip: Clip? { get }
    var operation: AnyPublisher<ClipCollection.Operation, Never> { get }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { get }
    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { get }

    // MARK: Selection

    var selected: PassthroughSubject<Set<Clip>, Never> { get }
    var deselected: PassthroughSubject<Set<Clip>, Never> { get }

    // MARK: Other Actions

    var previewed: PassthroughSubject<Clip.Identity, Never> { get }
    var displayErrorMessage: PassthroughSubject<String, Never> { get }
    var startMerging: PassthroughSubject<[Clip], Never> { get }
    var startSharing: PassthroughSubject<ClipCollection.ShareContext, Never> { get }

    func resolveTags(for clipId: Clip.Identity) -> [Tag.Identity]
}

final class ClipCollectionViewModel: ClipCollectionViewModelType,
    ClipCollectionViewModelInputs,
    ClipCollectionViewModelOutputs
{
    // MARK: - ClipCollectionViewModelType

    var inputs: ClipCollectionViewModelInputs { self }
    var outputs: ClipCollectionViewModelOutputs { self }

    // MARK: - ClipCollectionViewModelInputs

    let operationRequested: PassthroughSubject<ClipCollection.Operation, Never> = .init()
    let clipsFetched: PassthroughSubject<[Clip], Never> = .init()
    let dismissedPreview: PassthroughSubject<Void, Never> = .init()

    let select: PassthroughSubject<Clip.Identity, Never> = .init()
    let deselect: PassthroughSubject<Clip.Identity, Never> = .init()
    let selectAll: PassthroughSubject<Void, Never> = .init()
    let deselectAll: PassthroughSubject<Void, Never> = .init()

    let deleteSelections: PassthroughSubject<Void, Never> = .init()
    let hideSelections: PassthroughSubject<Void, Never> = .init()
    let revealSelections: PassthroughSubject<Void, Never> = .init()
    let addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> = .init()
    let addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let mergeSelections: PassthroughSubject<Void, Never> = .init()
    let shareSelections: PassthroughSubject<Void, Never> = .init()

    let delete: PassthroughSubject<Clip.Identity, Never> = .init()
    let hide: PassthroughSubject<Clip.Identity, Never> = .init()
    let reveal: PassthroughSubject<Clip.Identity, Never> = .init()
    let purge: PassthroughSubject<Clip.Identity, Never> = .init()
    let replaceTags: PassthroughSubject<ClipCollection.TagsReplacingRequest, Never> = .init()
    let addToAlbum: PassthroughSubject<ClipCollection.AddingToAlbumRequest, Never> = .init()
    let share: PassthroughSubject<Clip.Identity, Never> = .init()

    // MARK: - ClipCollectionViewModelOutputs

    var clips: AnyPublisher<[Clip], Never> {
        _clips.map { $0
            .map { $0.value }
            .sorted(by: { $0.registeredDate > $1.registeredDate })
        }
        .eraseToAnyPublisher()
    }

    var selectedClips: AnyPublisher<[Clip], Never> {
        _selections.combineLatest(_clips)
            .map { selections, dict in
                selections.compactMap { id in dict[id] }
            }
            .eraseToAnyPublisher()
    }

    var selections: Set<Clip.Identity> { _selections.value }

    var previewingClip: Clip? {
        guard let clipId = _previewingClipId.value else { return nil }
        return _clips.value[clipId]
    }

    var operation: AnyPublisher<ClipCollection.Operation, Never> {
        _operation.eraseToAnyPublisher()
    }

    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> {
        _isEmptyMessageDisplaying.eraseToAnyPublisher()
    }

    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> {
        _isCollectionViewDisplaying.eraseToAnyPublisher()
    }

    let selected: PassthroughSubject<Set<Clip>, Never> = .init()
    let deselected: PassthroughSubject<Set<Clip>, Never> = .init()

    let previewed: PassthroughSubject<Clip.Identity, Never> = .init()
    let displayErrorMessage: PassthroughSubject<String, Never> = .init()
    let startMerging: PassthroughSubject<[Clip], Never> = .init()
    let startSharing: PassthroughSubject<ClipCollection.ShareContext, Never> = .init()

    // MARK: Privates

    private let _clips: CurrentValueSubject<[Clip.Identity: Clip], Never> = .init([:])
    private let _selections: CurrentValueSubject<Set<Clip.Identity>, Never> = .init([])
    private let _operation: CurrentValueSubject<ClipCollection.Operation, Never> = .init(.none)
    private let _isEmptyMessageDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _isCollectionViewDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _previewingClipId: CurrentValueSubject<Clip.Identity?, Never> = .init(nil)

    private let clipService: ClipCommandServiceProtocol
    private let imageQueryService: ImageQueryServiceProtocol
    private let logger: TBoxLoggable

    private var subscriptions = Set<AnyCancellable>()

    private var _selectedClips: [Clip] {
        _selections.value.compactMap { _clips.value[$0] }
    }

    private var selectedClipIds: [Clip.Identity] { Array(self._selections.value) }

    // MARK: - Initializer

    init(clipService: ClipCommandServiceProtocol,
         imageQueryService: ImageQueryServiceProtocol,
         logger: TBoxLoggable)
    {
        self.clipService = clipService
        self.imageQueryService = imageQueryService
        self.logger = logger

        self.bind()
    }
}

extension ClipCollectionViewModel {
    func resolveTags(for clipId: Clip.Identity) -> [Tag.Identity] {
        guard let clip = _clips.value[clipId] else { return [] }
        return clip.tags.map { $0.id }
    }
}

// MARK: - Load Images

extension ClipCollectionViewModel {
    private func fetchImages(for clipId: Clip.Identity) -> [Data] {
        guard let clip = _clips.value[clipId] else {
            displayErrorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
        do {
            let images = try clip.items
                .map { $0.imageId }
                .compactMap { [weak self] imageId in try self?.imageQueryService.read(having: imageId) }
            return images
        } catch {
            self.displayErrorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
    }

    private func fetchImagesForSelections() -> [Data] {
        do {
            let images = try self._selectedClips
                .flatMap { $0.items }
                .map { $0.imageId }
                .compactMap { try self.imageQueryService.read(having: $0) }
            return images
        } catch {
            self.displayErrorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
    }
}

// MARK: - Bind

extension ClipCollectionViewModel {
    private func bind() {
        self.configureState()
        self.configureSelections()
        self.configureActionsForClip()
        self.configureActionsForSelections()
    }

    private func configureState() {
        self.clipsFetched
            .sink { [weak self] clips in
                guard let self = self else { return }

                self._clips.send(clips.reduce(into: [Clip.Identity: Clip](), { $0[$1.id] = $1 }))

                // 余分な選択を除外する
                let newClipIds = Set(clips.map { $0.id })
                if !self._selections.value.isSubset(of: newClipIds) {
                    self._selections.send(self._selections.value.subtracting(self._selections.value.subtracting(newClipIds)))
                }
            }
            .store(in: &subscriptions)

        self._clips
            .map { $0.isEmpty }
            .sink { [weak self] isEmpty in
                if isEmpty {
                    self?._isCollectionViewDisplaying.send(false)
                    self?._isEmptyMessageDisplaying.send(true)
                } else {
                    self?._isEmptyMessageDisplaying.send(false)
                    self?._isCollectionViewDisplaying.send(true)
                }
            }
            .store(in: &subscriptions)

        self.operationRequested
            .sink { [weak self] operation in
                self?.deselectAll.send(())
                self?._operation.send(operation)
            }
            .store(in: &subscriptions)

        self.dismissedPreview
            .sink { [weak self] _ in
                self?._previewingClipId.send(nil)
            }
            .store(in: &subscriptions)
    }

    private func configureSelections() {
        self.select
            .sink { [weak self] clipId in
                guard let self = self, let clip = self._clips.value[clipId] else { return }
                let selections: Set<Clip.Identity> = {
                    if self._operation.value.isAllowedMultipleSelection {
                        return self._selections.value.union(Set([clipId]))
                    } else {
                        return Set([clipId])
                    }
                }()

                self._selections.send(selections)
                self.selected.send(Set([clip]))

                if !self._operation.value.isAllowedMultipleSelection,
                    let clip = self._clips.value[clipId]
                {
                    self._previewingClipId.send(clip.id)
                    self.previewed.send(clipId)
                }
            }
            .store(in: &self.subscriptions)

        self.selectAll
            .sink { [weak self] _ in
                guard let self = self, self._operation.value.isAllowedMultipleSelection else { return }
                self._selections.send(Set(self._clips.value.keys))
                self.selected.send(Set(self._clips.value.values))
            }
            .store(in: &self.subscriptions)

        self.deselect
            .sink { [weak self] clipId in
                guard let self = self,
                    self._selections.value.contains(clipId),
                    let clip = self._clips.value[clipId] else { return }
                self._selections.send(self._selections.value.subtracting(Set([clipId])))
                self.deselected.send(Set([clip]))
            }
            .store(in: &self.subscriptions)

        self.deselectAll
            .sink { [weak self] _ in
                guard let self = self else { return }
                let targets = self._selections.value
                    .compactMap { self._clips.value[$0] }
                self._selections.send([])
                self.deselected.send(Set(targets))
            }
            .store(in: &self.subscriptions)
    }

    func configureActionsForSelections() {
        self.deleteSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.deleteClips(having: self.selectedClipIds) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtDeleteClips)
                }
                self._operation.send(.none)
            }
            .store(in: &self.subscriptions)

        self.hideSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClipIds, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップの非表示に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtHideClips)
                }
                self._operation.send(.none)
            }
            .store(in: &self.subscriptions)

        self.revealSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClipIds, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップの表示に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtUnhideClips)
                }
                self._operation.send(.none)
            }
            .store(in: &self.subscriptions)

        self.addTagsToSelections
            .sink { [weak self] tagIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClipIds, byAddingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップへのタグの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtUpdateTagsToClips)
                }
                self._operation.send(.none)
            }
            .store(in: &self.subscriptions)

        self.addSelectionsToAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: self.selectedClipIds) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップのアルバムへの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtAddClipsToAlbum)
                }
                self._operation.send(.none)
            }
            .store(in: &self.subscriptions)

        self.mergeSelections
            .sink { [weak self] in
                guard let self = self else { return }
                self.startMerging.send(self._selectedClips)
            }
            .store(in: &self.subscriptions)

        self.shareSelections
            .sink { [weak self] in
                guard let self = self else { return }
                self.startSharing.send(.init(source: .toolBar, data: self.fetchImagesForSelections()))
            }
            .store(in: &self.subscriptions)
    }

    private func configureActionsForClip() {
        self.delete
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.deleteClips(having: [id]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtDeleteClip)
                }
            }
            .store(in: &self.subscriptions)

        self.hide
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップのHideに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtHideClip)
                }
            }
            .store(in: &self.subscriptions)

        self.reveal
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップのUnhideに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtUnhideClip)
                }
            }
            .store(in: &self.subscriptions)

        self.purge
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.purgeClipItems(forClipHaving: id) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの分割に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtPurge)
                }
            }
            .store(in: &self.subscriptions)

        self.replaceTags
            .sink { [weak self] request in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [request.target], byReplacingTagsHaving: Array(request.tags)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    タグの追加に失敗 (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtUpdateTagsToClip)
                }
            }
            .store(in: &self.subscriptions)

        self.addToAlbum
            .sink { [weak self] request in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: request.target, byAddingClipsHaving: Array(request.clips)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムへの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtAddClipToAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.share
            .sink { [weak self] clipId in
                guard let self = self, let clip = self._clips.value[clipId] else { return }
                self.startSharing.send(.init(source: .menu(clip), data: self.fetchImages(for: clipId)))
            }
            .store(in: &self.subscriptions)
    }
}
