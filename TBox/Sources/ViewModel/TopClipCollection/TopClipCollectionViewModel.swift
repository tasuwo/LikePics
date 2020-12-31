//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TopClipCollectionViewModelInputs {
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }

    var viewDidAppear: PassthroughSubject<Void, Never> { get }
    var cancelledPreview: PassthroughSubject<Void, Never> { get }

    var select: PassthroughSubject<Clip.Identity, Never> { get }
    var deselect: PassthroughSubject<Clip.Identity, Never> { get }
    var selectAll: PassthroughSubject<Void, Never> { get }
    var deselectAll: PassthroughSubject<Void, Never> { get }

    var deleteSelections: PassthroughSubject<Void, Never> { get }
    var hideSelections: PassthroughSubject<Void, Never> { get }
    var unhideSelections: PassthroughSubject<Void, Never> { get }
    var addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> { get }
    var addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> { get }
    var mergeSelections: PassthroughSubject<Void, Never> { get }
    var shareSelections: PassthroughSubject<Void, Never> { get }

    var delete: PassthroughSubject<Clip.Identity, Never> { get }
    var hide: PassthroughSubject<Clip.Identity, Never> { get }
    var unhide: PassthroughSubject<Clip.Identity, Never> { get }
    var purge: PassthroughSubject<Clip.Identity, Never> { get }
    var addTags: PassthroughSubject<(having: Set<Tag.Identity>, to: Clip.Identity), Never> { get }
    var addToAlbum: PassthroughSubject<(having: Album.Identity, Clip.Identity), Never> { get }
    var share: PassthroughSubject<Clip.Identity, Never> { get }
}

protocol TopClipCollectionViewModelOutputs {
    var clips: CurrentValueSubject<[Clip], Never> { get }
    var selectedClips: [Clip] { get }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { get }
    // 選択状態はクリップの更新により解除されてしまうことがあるため、selectionsとは別途管理する
    var previewingClip: Clip? { get }

    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }

    var presentPreview: PassthroughSubject<Clip.Identity, Never> { get }
    var presentMergeView: PassthroughSubject<[Clip], Never> { get }
    var startShareForContextMenu: PassthroughSubject<(Clip.Identity, [Data]), Never> { get }
    var startShareForToolBar: PassthroughSubject<[Data], Never> { get }
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

    let viewDidAppear: PassthroughSubject<Void, Never> = .init()
    let cancelledPreview: PassthroughSubject<Void, Never> = .init()

    var select: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.select }
    var deselect: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.deselect }
    var selectAll: PassthroughSubject<Void, Never> { clipCollection.inputs.selectAll }
    var deselectAll: PassthroughSubject<Void, Never> { clipCollection.inputs.deselectAll }

    var deleteSelections: PassthroughSubject<Void, Never> { clipCollection.inputs.deleteSelections }
    var hideSelections: PassthroughSubject<Void, Never> { clipCollection.inputs.hideSelections }
    var unhideSelections: PassthroughSubject<Void, Never> { clipCollection.inputs.unhideSelections }
    var addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> { clipCollection.inputs.addTagsToSelections }
    var addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> { clipCollection.inputs.addSelectionsToAlbum }
    var mergeSelections: PassthroughSubject<Void, Never> { clipCollection.inputs.mergeSelections }
    var shareSelections: PassthroughSubject<Void, Never> { clipCollection.inputs.shareSelections }

    var delete: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.delete }
    var hide: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.hide }
    var unhide: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.unhide }
    var purge: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.purge }
    var addTags: PassthroughSubject<(having: Set<Tag.Identity>, to: Clip.Identity), Never> { clipCollection.inputs.updateTags }
    var addToAlbum: PassthroughSubject<(having: Album.Identity, Clip.Identity), Never> { clipCollection.inputs.addToAlbum }
    var share: PassthroughSubject<Clip.Identity, Never> { clipCollection.inputs.share }

    // MARK: TopClipCollectionViewModelOutputs

    var clips: CurrentValueSubject<[Clip], Never> { clipCollection.outputs.clips }
    var selectedClips: [Clip] { clipCollection.outputs.selectedClips }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { clipCollection.outputs.selections }
    var previewingClip: Clip? {
        return self.clips.value.first(where: { $0.id == self.previewingClipId })
    }

    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { clipCollection.outputs.operation }
    var errorMessage: PassthroughSubject<String, Never> { clipCollection.outputs.errorMessage }

    let presentPreview: PassthroughSubject<Clip.Identity, Never> = .init()
    var presentMergeView: PassthroughSubject<[Clip], Never> { clipCollection.outputs.requestedStartingMerge }
    var startShareForContextMenu: PassthroughSubject<(Clip.Identity, [Data]), Never> { clipCollection.outputs.requestedShareClip }
    var startShareForToolBar: PassthroughSubject<[Data], Never> { clipCollection.outputs.requestedShareClips }

    // MARK: Privates

    private let query: ClipListQuery
    private let clipCollection: ClipCollectionModelType
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var previewingClipId: Clip.Identity?
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: ClipListQuery,
         composition: ClipCollectionModelType,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clipCollection = composition
        self.settingStorage = settingStorage
        self.logger = logger

        self.bind()
    }
}

extension TopClipCollectionViewModel {
    // MARK: - Binding

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
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })
                    .sorted(by: { $0.registeredDate > $1.registeredDate })
                self.clips.send(newClips)

                // 余分な選択を除外する
                let newClipIds = Set(self.clips.value.map { $0.identity })
                if !self.selections.value.isSubset(of: newClipIds) {
                    self.selections.send(self.selections.value.subtracting(self.selections.value.subtracting(newClipIds)))
                }
            }
            .store(in: &self.cancellableBag)

        self.viewDidAppear
            .sink { [weak self] _ in self?.previewingClipId = nil }
            .store(in: &self.cancellableBag)

        self.cancelledPreview
            .sink { [weak self] _ in self?.previewingClipId = nil }
            .store(in: &self.cancellableBag)

        self.clipCollection.outputs.selectedSingleClip
            .sink { [weak self] clipId in
                self?.previewingClipId = clipId
                self?.presentPreview.send(clipId)
            }
            .store(in: &self.cancellableBag)
    }
}
