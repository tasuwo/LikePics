//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TopClipCollectionViewModelInputs {
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
}

protocol TopClipCollectionViewModelOutputs {
    // MARK: State

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

    func resolveTags(for clipId: Clip.Identity) -> [Tag.Identity]
}

protocol TopClipCollectionViewModelType {
    var inputs: TopClipCollectionViewModelInputs { get }
    var outputs: TopClipCollectionViewModelOutputs { get }
    var propagator: ClipCollectionStatePropagable { get }
}

class TopClipCollectionViewModel: TopClipCollectionViewModelType,
    TopClipCollectionViewModelInputs,
    TopClipCollectionViewModelOutputs,
    ClipCollectionStatePropagable
{
    // MARK: - Properties

    // MARK: TopClipCollectionViewModelType

    var inputs: TopClipCollectionViewModelInputs { self }
    var outputs: TopClipCollectionViewModelOutputs { self }
    var propagator: ClipCollectionStatePropagable { self }

    // MARK: TopClipCollectionViewModelInputs

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

    // MARK: TopClipCollectionViewModelOutputs

    var clips: AnyPublisher<[Clip], Never> { _viewModel.outputs.clips }
    var selectedClips: AnyPublisher<[Clip], Never> { _viewModel.outputs.selectedClips }
    var previewingClip: Clip? { _viewModel.outputs.previewingClip }
    var operation: AnyPublisher<ClipCollection.Operation, Never> { _viewModel.outputs.operation }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { _viewModel.outputs.isEmptyMessageDisplaying }
    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { _viewModel.outputs.isCollectionViewDisplaying }

    var selected: PassthroughSubject<Set<Clip>, Never> { _viewModel.outputs.selected }
    var deselected: PassthroughSubject<Set<Clip>, Never> { _viewModel.outputs.deselected }

    var previewed: PassthroughSubject<Clip.Identity, Never> { _viewModel.outputs.previewed }
    var displayErrorMessage: PassthroughSubject<String, Never> { _viewModel.outputs.displayErrorMessage }
    var startMerging: PassthroughSubject<[Clip], Never> { _viewModel.outputs.startMerging }
    var startSharing: PassthroughSubject<ClipCollection.ShareContext, Never> { _viewModel.outputs.startSharing }

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

    private let query: ClipListQuery
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable
    private let _viewModel: ClipCollectionViewModelType
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: ClipListQuery,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable,
         viewModel: ClipCollectionViewModelType)
    {
        self.query = query
        self.settingStorage = settingStorage
        self.logger = logger
        self._viewModel = viewModel

        self.bind()
    }
}

extension TopClipCollectionViewModel {
    func resolveTags(for clipId: Clip.Identity) -> [Tag.Identity] {
        return _viewModel.outputs.resolveTags(for: clipId)
    }
}

// MARK: - Binding

extension TopClipCollectionViewModel {
    private func bind() {
        self.query.clips
            .catch { _ -> AnyPublisher<[Clip], Never> in
                return Just([Clip]()).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
            .combineLatest(self.settingStorage.showHiddenItems)
            .sink { [weak self] clips, showHiddenItems in
                guard let self = self else { return }

                let newClips = clips
                    .filter { clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    }

                self._viewModel.inputs.clipsFetched.send(newClips)
            }
            .store(in: &self.subscriptions)

        self.viewDidAppear
            .sink { [weak self] _ in self?._viewModel.inputs.dismissedPreview.send(()) }
            .store(in: &self.subscriptions)

        self.previewCancelled
            .sink { [weak self] _ in self?._viewModel.inputs.dismissedPreview.send(()) }
            .store(in: &self.subscriptions)
    }
}
