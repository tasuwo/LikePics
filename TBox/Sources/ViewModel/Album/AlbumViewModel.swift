//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol AlbumViewModelInputs {
    // MARK: State

    var operationRequested: PassthroughSubject<ClipCollection.Operation, Never> { get }
    var viewDidAppear: PassthroughSubject<Void, Never> { get }
    var previewCancelled: PassthroughSubject<Void, Never> { get }

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

    // MARK: Actions for Album

    var removeSelectionsFromAlbum: PassthroughSubject<Void, Never> { get }
    var removeFromAlbum: PassthroughSubject<Clip.Identity, Never> { get }
    var reorder: PassthroughSubject<[Clip.Identity], Never> { get }
}

protocol AlbumViewModelOutputs {
    // MARK: State

    var title: CurrentValueSubject<String, Never> { get }
    var album: CurrentValueSubject<Album, Never> { get }
    var clips: AnyPublisher<[Clip], Never> { get }
    var selectedClips: AnyPublisher<[Clip], Never> { get }
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

    var close: PassthroughSubject<Void, Never> { get }

    func resolveTags(for clipId: Clip.Identity) -> [Tag.Identity]
}

protocol AlbumViewModelType {
    var inputs: AlbumViewModelInputs { get }
    var outputs: AlbumViewModelOutputs { get }
    var propagator: ClipCollectionStatePropagable { get }
}

class AlbumViewModel: AlbumViewModelType,
    AlbumViewModelInputs,
    AlbumViewModelOutputs,
    ClipCollectionStatePropagable
{
    // MARK: - Properties

    // MARK: AlbumViewModelType

    var inputs: AlbumViewModelInputs { self }
    var outputs: AlbumViewModelOutputs { self }
    var propagator: ClipCollectionStatePropagable { self }

    // MARK: AlbumViewModelInputs

    var operationRequested: PassthroughSubject<ClipCollection.Operation, Never> { _viewModel.inputs.operationRequested }
    let viewDidAppear: PassthroughSubject<Void, Never> = .init()
    let previewCancelled: PassthroughSubject<Void, Never> = .init()

    var select: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.select }
    var deselect: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.deselect }
    var selectAll: PassthroughSubject<Void, Never> { _viewModel.inputs.selectAll }
    var deselectAll: PassthroughSubject<Void, Never> { _viewModel.inputs.deselectAll }

    var deleteSelections: PassthroughSubject<Void, Never> { _viewModel.inputs.deleteSelections }
    var hideSelections: PassthroughSubject<Void, Never> { _viewModel.inputs.hideSelections }
    var revealSelections: PassthroughSubject<Void, Never> { _viewModel.inputs.revealSelections }
    var addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> { _viewModel.inputs.addTagsToSelections }
    var addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> { _viewModel.inputs.addSelectionsToAlbum }
    var mergeSelections: PassthroughSubject<Void, Never> { _viewModel.inputs.mergeSelections }
    var shareSelections: PassthroughSubject<Void, Never> { _viewModel.inputs.shareSelections }

    var delete: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.delete }
    var hide: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.hide }
    var reveal: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.reveal }
    var purge: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.purge }
    var replaceTags: PassthroughSubject<ClipCollection.TagsReplacingRequest, Never> { _viewModel.inputs.replaceTags }
    var addToAlbum: PassthroughSubject<ClipCollection.AddingToAlbumRequest, Never> { _viewModel.inputs.addToAlbum }
    var share: PassthroughSubject<Clip.Identity, Never> { _viewModel.inputs.share }

    let removeSelectionsFromAlbum: PassthroughSubject<Void, Never> = .init()
    let removeFromAlbum: PassthroughSubject<Clip.Identity, Never> = .init()
    let reorder: PassthroughSubject<[Clip.Identity], Never> = .init()

    // MARK: AlbumViewModelOutputs

    let title: CurrentValueSubject<String, Never>
    let album: CurrentValueSubject<Album, Never>
    var clips: AnyPublisher<[Clip], Never> { _viewModel.outputs.clips }
    var selectedClips: AnyPublisher<[Clip], Never> { _viewModel.outputs.selectedClips }
    var previewingClip: Clip? { _viewModel.outputs.previewingClip }
    var operation: AnyPublisher<ClipCollection.Operation, Never> { _viewModel.outputs.operation }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { _viewModel.outputs.isEmptyMessageDisplaying }
    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { _viewModel.outputs.isCollectionViewDisplaying }

    var selected: PassthroughSubject<Set<Clip>, Never> { _viewModel.outputs.selected }
    var deselected: PassthroughSubject<Set<Clip>, Never> { _viewModel.outputs.deselected }

    var previewed: PassthroughSubject<Clip.Identity, Never> { _viewModel.outputs.previewed }
    var displayErrorMessage: PassthroughSubject<String, Never> = .init()
    var startMerging: PassthroughSubject<[Clip], Never> { _viewModel.outputs.startMerging }
    var startSharing: PassthroughSubject<ClipCollection.ShareContext, Never> { _viewModel.outputs.startSharing }

    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: ClipCollectionStatePropagable

    var clipsCount: AnyPublisher<Int, Never> {
        clips.map { $0.count }.eraseToAnyPublisher()
    }

    var selectionsCount: AnyPublisher<Int, Never> {
        selectedClips.map { $0.count }.eraseToAnyPublisher()
    }

    var currentOperation: AnyPublisher<ClipCollection.Operation, Never> {
        operation.eraseToAnyPublisher()
    }

    var startShareForToolBar: AnyPublisher<[Data], Never> {
        startSharing
            .filter { $0.source == .toolBar }
            .map { $0.data }
            .assertNoFailure()
            .eraseToAnyPublisher()
    }

    // MARK: Privates

    private let query: AlbumQuery
    private let clipService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable
    private let _viewModel: ClipCollectionViewModelType
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: AlbumQuery,
         clipService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable,
         viewModel: ClipCollectionViewModelType)
    {
        self.query = query
        self.clipService = clipService
        self.settingStorage = settingStorage
        self.logger = logger
        self._viewModel = viewModel

        self.album = .init(query.album.value)
        self.title = .init(query.album.value.title)

        self.bind()
    }
}

extension AlbumViewModel {
    func resolveTags(for clipId: Clip.Identity) -> [Tag.Identity] {
        return _viewModel.outputs.resolveTags(for: clipId)
    }
}

extension AlbumViewModel {
    // MARK: - Binding

    private func bind() {
        self.album
            .compactMap { $0 }
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink(receiveCompletion: { [weak self] _ in
                self?.logger.write(ConsoleLog(level: .error, message: """
                Unexpectedly finished observing at AlbumView.
                """))
            }, receiveValue: { [weak self] album, showHiddenItems in
                guard let self = self else { return }

                let newClips = album.clips
                    .filter { clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    }

                self._viewModel.inputs.clipsFetched.send(newClips)
            })
            .store(in: &self.subscriptions)

        self.album
            .sink { [weak self] album in self?.title.send(album.title) }
            .store(in: &self.subscriptions)

        self.query.album
            .eraseToAnyPublisher()
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] album in
                self?.album.send(album)
            }
            .store(in: &self.subscriptions)

        self._viewModel.outputs.displayErrorMessage
            .sink { [weak self] message in self?.displayErrorMessage.send(message) }
            .store(in: &self.subscriptions)

        self.viewDidAppear
            .sink { [weak self] _ in self?._viewModel.inputs.dismissedPreview.send(()) }
            .store(in: &self.subscriptions)

        self.previewCancelled
            .sink { [weak self] _ in self?._viewModel.inputs.dismissedPreview.send(()) }
            .store(in: &self.subscriptions)

        self.removeSelectionsFromAlbum
            .sink { [weak self] _ in
                guard let self = self else { return }
                let clipIds = Array(self._viewModel.outputs.selections)
                if case let .failure(error) = self.clipService.updateAlbum(having: self.album.value.identity, byDeletingClipsHaving: clipIds) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムからのクリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.removeFromAlbum
            .sink { [weak self] clipId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: self.album.value.identity, byDeletingClipsHaving: [clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムからのクリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
                }
            }
            .store(in: &self.subscriptions)

        self.reorder
            .sink { [weak self] clipIds in
                guard let self = self else { return }

                let originals = self.query.album.value.clips.map({ $0.id })
                guard Set(originals).count == originals.count, Set(clipIds).count == clipIds.count else {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムの並び替えに失敗しました。IDに重複が存在します
                    """))
                    self.displayErrorMessage.send(L10n.albumListViewErrorAtReorderAlbum)
                    return
                }

                let ids = self.performReorder(originals: originals, request: clipIds)
                if case let .failure(error) = self.clipService.updateAlbum(having: self.album.value.identity, byReorderingClipsHaving: ids) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    並び替えに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtReorder)
                }
            }
            .store(in: &self.subscriptions)
    }

    private func performReorder(originals: [Clip.Identity], request: [Clip.Identity]) -> [Clip.Identity] {
        var index = 0
        return originals
            .map { original in
                guard request.contains(original) else { return original }
                index += 1
                return request[index - 1]
            }
    }
}
