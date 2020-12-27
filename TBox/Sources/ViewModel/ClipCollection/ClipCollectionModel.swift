//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipCollectionModelType {
    var inputs: ClipCollectionModelInputs { get }
    var outputs: ClipCollectionModelOutputs { get }
}

protocol ClipCollectionModelInputs {
    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
    var clips: CurrentValueSubject<[Clip], Never> { get }

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
    var updateTags: PassthroughSubject<(having: Set<Tag.Identity>, to: Clip.Identity), Never> { get }
    var addToAlbum: PassthroughSubject<(having: Album.Identity, Clip.Identity), Never> { get }
    var share: PassthroughSubject<Clip.Identity, Never> { get }
}

protocol ClipCollectionModelOutputs {
    var clips: CurrentValueSubject<[Clip], Never> { get }
    var selectedClips: [Clip] { get }
    var selections: CurrentValueSubject<Set<Clip.Identity>, Never> { get }

    var operation: CurrentValueSubject<ClipCollection.Operation, Never> { get }
    var errorMessage: PassthroughSubject<String, Never> { get }

    var requestedStartingMerge: PassthroughSubject<[Clip], Never> { get }
    var requestedShareClips: PassthroughSubject<[Data], Never> { get }
    var requestedShareClip: PassthroughSubject<(Clip.Identity, [Data]), Never> { get }
    var selectedSingleClip: PassthroughSubject<Clip.Identity, Never> { get }
}

class ClipCollectionModel: ClipCollectionModelType,
    ClipCollectionModelInputs,
    ClipCollectionModelOutputs
{
    // MARK: - Properties

    // MARK: ClipCollectionModelType

    var inputs: ClipCollectionModelInputs { self }
    var outputs: ClipCollectionModelOutputs { self }

    // MARK: ClipCollectionModelInputs

    let select: PassthroughSubject<Clip.Identity, Never> = .init()
    let deselect: PassthroughSubject<Clip.Identity, Never> = .init()
    let selectAll: PassthroughSubject<Void, Never> = .init()
    let deselectAll: PassthroughSubject<Void, Never> = .init()

    let deleteSelections: PassthroughSubject<Void, Never> = .init()
    let hideSelections: PassthroughSubject<Void, Never> = .init()
    let unhideSelections: PassthroughSubject<Void, Never> = .init()
    let addTagsToSelections: PassthroughSubject<Set<Tag.Identity>, Never> = .init()
    let addSelectionsToAlbum: PassthroughSubject<Album.Identity, Never> = .init()
    let mergeSelections: PassthroughSubject<Void, Never> = .init()
    let shareSelections: PassthroughSubject<Void, Never> = .init()

    let delete: PassthroughSubject<Clip.Identity, Never> = .init()
    let hide: PassthroughSubject<Clip.Identity, Never> = .init()
    let unhide: PassthroughSubject<Clip.Identity, Never> = .init()
    let purge: PassthroughSubject<Clip.Identity, Never> = .init()
    let updateTags: PassthroughSubject<(having: Set<Tag.Identity>, to: Clip.Identity), Never> = .init()
    let addToAlbum: PassthroughSubject<(having: Album.Identity, Clip.Identity), Never> = .init()
    let share: PassthroughSubject<Clip.Identity, Never> = .init()

    // MARK: ClipCollectionModelOutputs

    let clips: CurrentValueSubject<[Clip], Never> = .init([])
    // TODO: パフォーマンス改善
    var selectedClips: [Clip] {
        return self.selections.value
            .compactMap { selection in
                return self.clips.value.first(where: { selection == $0.identity })
            }
    }

    let selections: CurrentValueSubject<Set<Clip.Identity>, Never> = .init([])
    let operation: CurrentValueSubject<ClipCollection.Operation, Never> = .init(.none)
    let errorMessage: PassthroughSubject<String, Never> = .init()

    let requestedStartingMerge: PassthroughSubject<[Clip], Never> = .init()
    let requestedShareClips: PassthroughSubject<[Data], Never> = .init()
    let requestedShareClip: PassthroughSubject<(Clip.Identity, [Data]), Never> = .init()
    let selectedSingleClip: PassthroughSubject<Clip.Identity, Never> = .init()

    // MARK: Privates

    private let clipService: ClipCommandServiceProtocol
    private let imageQueryService: NewImageQueryServiceProtocol
    private let logger: TBoxLoggable

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(clipService: ClipCommandServiceProtocol,
         imageQueryService: NewImageQueryServiceProtocol,
         logger: TBoxLoggable)
    {
        self.clipService = clipService
        self.imageQueryService = imageQueryService
        self.logger = logger

        self.bind()
    }

    // MARK: - Methods

    private func fetchImages(for clipId: Clip.Identity) -> [Data] {
        guard let clip = self.clips.value.first(where: { $0.id == clipId }) else {
            self.errorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
        do {
            let images = try clip.items
                .map { $0.imageId }
                .compactMap { [weak self] imageId in try self?.imageQueryService.read(having: imageId) }
            return images
        } catch {
            self.errorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
    }

    private func fetchImagesForSelections() -> [Data] {
        do {
            let images = try self.selectedClips
                .flatMap { $0.items }
                .map { $0.imageId }
                .compactMap { try self.imageQueryService.read(having: $0) }
            return images
        } catch {
            self.errorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
    }
}

extension ClipCollectionModel {
    // MARK: - Bind

    private func bind() {
        self.operation
            .sink { [weak self] _ in self?.deselectAll.send(()) }
            .store(in: &self.cancellableBag)

        self.bindSelectOperations()
        self.bindClipOperations()
    }

    private func bindSelectOperations() {
        self.select
            .sink { [weak self] clipId in
                guard let self = self else { return }
                if self.operation.value.isAllowedMultipleSelection {
                    self.selections.send(self.selections.value.union(Set([clipId])))
                } else {
                    self.selections.send(Set([clipId]))
                    self.selectedSingleClip.send(clipId)
                }
            }
            .store(in: &self.cancellableBag)

        self.selectAll
            .sink { [weak self] _ in
                guard let self = self, self.operation.value.isAllowedMultipleSelection else { return }
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
                    選択中のクリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtDeleteClips)
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.hideSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップのHideに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtHideClips)
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.unhideSelections
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップのUnhideに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtUnhideClips)
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.addTagsToSelections
            .sink { [weak self] tagIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: self.selectedClips.ids, byAddingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップへのタグの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtUpdateTagsToClips)
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.addSelectionsToAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: Array(self.selections.value)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    選択中のクリップのアルバムへの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtAddClipsToAlbum)
                }
                self.operation.send(.none)
            }
            .store(in: &self.cancellableBag)

        self.mergeSelections
            .sink { [weak self] in
                guard let self = self else { return }
                self.requestedStartingMerge.send(self.selectedClips)
            }
            .store(in: &self.cancellableBag)

        self.shareSelections
            .sink { [weak self] in
                guard let self = self else { return }
                self.requestedShareClips.send(self.fetchImagesForSelections())
            }
            .store(in: &self.cancellableBag)
    }

    private func bindClipOperations() {
        self.delete
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.deleteClips(having: [id]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtDeleteClip)
                }
            }
            .store(in: &self.cancellableBag)

        self.hide
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップのHideに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtHideClip)
                }
            }
            .store(in: &self.cancellableBag)

        self.unhide
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [id], byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップのUnhideに失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtUnhideClip)
                }
            }
            .store(in: &self.cancellableBag)

        self.purge
            .sink { [weak self] id in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.purgeClipItems(forClipHaving: id) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの分割に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtPurge)
                }
            }
            .store(in: &self.cancellableBag)

        self.updateTags
            .sink { [weak self] tagIds, clipId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateClips(having: [clipId], byReplacingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    タグの追加に失敗 (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtUpdateTagsToClip)
                }
            }
            .store(in: &self.cancellableBag)

        self.addToAlbum
            .sink { [weak self] albumId, clipId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipService.updateAlbum(having: albumId, byAddingClipsHaving: [clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムへの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtAddClipToAlbum)
                }
            }
            .store(in: &self.cancellableBag)

        self.share
            .sink { [weak self] clipId in
                guard let self = self else { return }
                self.requestedShareClip.send((clipId, self.fetchImages(for: clipId)))
            }
            .store(in: &self.cancellableBag)
    }
}
