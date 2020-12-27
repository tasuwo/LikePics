//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol AlbumViewModelInputs {
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

    var removeSelectionsFromAlbum: PassthroughSubject<Void, Never> { get }
    var removeFromAlbum: PassthroughSubject<Clip.Identity, Never> { get }
    var reorder: PassthroughSubject<[Clip.Identity], Never> { get }
}

protocol AlbumViewModelOutputs {
    var album: CurrentValueSubject<Album, Never> { get }
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
    var close: PassthroughSubject<Void, Never> { get }

    var title: CurrentValueSubject<String?, Never> { get }
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

    let removeSelectionsFromAlbum: PassthroughSubject<Void, Never> = .init()
    let removeFromAlbum: PassthroughSubject<Clip.Identity, Never> = .init()
    let reorder: PassthroughSubject<[Clip.Identity], Never> = .init()

    // MARK: AlbumViewModelOutputs

    let album: CurrentValueSubject<Album, Never>
    var clips: CurrentValueSubject<[Clip], Never> { clipCollection.outputs.clips }
    var selectedClips: [Clip] { clipCollection.outputs.selectedClips }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { clipCollection.outputs.selections }
    var previewingClip: Clip? {
        return self.clips.value.first(where: { $0.id == self.previewingClipId })
    }

    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { clipCollection.outputs.operation }
    let errorMessage: PassthroughSubject<String, Never> = .init()
    let emptyMessage: CurrentValueSubject<String, Never> = .init("")

    let presentPreview: PassthroughSubject<Clip.Identity, Never> = .init()
    var presentMergeView: PassthroughSubject<[Clip], Never> { clipCollection.outputs.requestedStartingMerge }
    var startShareForContextMenu: PassthroughSubject<(Clip.Identity, [Data]), Never> { clipCollection.outputs.requestedShareClip }
    var startShareForToolBar: PassthroughSubject<[Data], Never> { clipCollection.outputs.requestedShareClips }
    let close: PassthroughSubject<Void, Never> = .init()

    let title: CurrentValueSubject<String?, Never> = .init(nil)

    // MARK: Privates

    private let query: AlbumQuery
    private let clipCollection: ClipCollectionModelType
    private let clipService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var previewingClipId: Clip.Identity?
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: AlbumQuery,
         composition: ClipCollectionModelType,
         clipService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clipCollection = composition
        self.clipService = clipService
        self.settingStorage = settingStorage
        self.logger = logger

        self.album = .init(query.album.value)

        self.bind()
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

                let newClips = album
                    .clips
                    .filter({ clip in
                        guard showHiddenItems else { return !clip.isHidden }
                        return true
                    })
                self.clips.send(newClips)

                // 余分な選択を除外する
                let newClipIds = Set(self.clips.value.map { $0.identity })
                if !self.selections.value.isSubset(of: newClipIds) {
                    self.selections.send(self.selections.value.subtracting(self.selections.value.subtracting(newClipIds)))
                }
            })
            .store(in: &self.cancellableBag)

        self.album
            .sink { [weak self] album in self?.title.send(album.title) }
            .store(in: &self.cancellableBag)

        self.query.album
            .eraseToAnyPublisher()
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] album in
                self?.album.send(album)
            }
            .store(in: &self.cancellableBag)

        self.clipCollection.outputs.errorMessage
            .sink { [weak self] message in self?.errorMessage.send(message) }
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

        self.removeSelectionsFromAlbum
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: self.album.value.identity, byDeletingClipsHaving: Array(self.selections.value)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムからのクリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.removeFromAlbum
            .sink { [weak self] clipId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: self.album.value.identity, byDeletingClipsHaving: [clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムからのクリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.reorder
            .sink { [weak self] clipIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: self.album.value.identity, byReorderingClipsHaving: clipIds) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    並び替えに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtReorder)
                }
            }
            .store(in: &self.cancellableBag)
    }
}
