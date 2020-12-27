//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol ClipPreviewPageViewModelType {
    var inputs: ClipPreviewPageViewModelInputs { get }
    var outputs: ClipPreviewPageViewModelOutputs { get }
}

protocol ClipPreviewPageViewModelInputs {
    var changedPage: PassthroughSubject<ClipItem.Identity, Never> { get }

    var deleteClip: PassthroughSubject<Void, Never> { get }
    var removeClipItem: PassthroughSubject<ClipItem.Identity, Never> { get }
    var replaceTags: PassthroughSubject<Set<Tag.Identity>, Never> { get }
    var addToAlbum: PassthroughSubject<Album.Identity, Never> { get }
}

protocol ClipPreviewPageViewModelOutputs {
    var clipId: Clip.Identity { get }

    var items: CurrentValueSubject<[ClipItem], Never> { get }
    var currentItem: CurrentValueSubject<ClipItem?, Never> { get }
    var tags: CurrentValueSubject<[Tag], Never> { get }

    var errorMessage: PassthroughSubject<String, Never> { get }

    var loadPageAt: PassthroughSubject<Int, Never> { get }
    var close: PassthroughSubject<Void, Never> { get }

    func fetchImage() -> Data?
    func fetchImagesInClip() -> [Data]
}

class ClipPreviewPageViewModel: ClipPreviewPageViewModelType,
    ClipPreviewPageViewModelInputs,
    ClipPreviewPageViewModelOutputs
{
    // MARK: - Properties

    // MARK: ClipPreviewPageViewModelType

    var inputs: ClipPreviewPageViewModelInputs { self }
    var outputs: ClipPreviewPageViewModelOutputs { self }

    // MARK: ClipPreviewPageViewModelInputs

    let changedPage: PassthroughSubject<ClipItem.Identity, Never> = .init()

    let deleteClip: PassthroughSubject<Void, Never> = .init()
    let removeClipItem: PassthroughSubject<ClipItem.Identity, Never> = .init()
    let replaceTags: PassthroughSubject<Set<Tag.Identity>, Never> = .init()
    let addToAlbum: PassthroughSubject<Album.Identity, Never> = .init()

    // MARK: ClipPreviewPageViewModelOutputs

    let clipId: Clip.Identity
    let items: CurrentValueSubject<[ClipItem], Never>
    let currentItem: CurrentValueSubject<ClipItem?, Never>
    let tags: CurrentValueSubject<[Tag], Never>

    let errorMessage: PassthroughSubject<String, Never> = .init()

    let loadPageAt: PassthroughSubject<Int, Never> = .init()
    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private let query: ClipQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let imageQueryService: NewImageQueryServiceProtocol
    private let logger: TBoxLoggable

    private let currentIndex: CurrentValueSubject<Int, Never>

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(clipId: Clip.Identity,
         query: ClipQuery,
         clipCommandService: ClipCommandServiceProtocol,
         imageQueryService: NewImageQueryServiceProtocol,
         logger: TBoxLoggable)
    {
        self.clipId = clipId
        self.query = query
        self.clipCommandService = clipCommandService
        self.imageQueryService = imageQueryService
        self.logger = logger

        self.items = .init(query.clip.value.sortedItems)
        self.currentItem = .init(query.clip.value.items.first)
        self.currentIndex = .init(0)
        self.tags = .init(query.clip.value.tags)

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.bindInputs()
        self.bindOutputs()
    }

    private func bindInputs() {
        self.query.clip
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] clip in
                guard let self = self else { return }
                let oldItem = clip.items[self.currentIndex.value]

                self.items.send(clip.items)
                self.tags.send(clip.tags)

                // 元のItemが削除されているようであれば、最初のページをロードする
                let newIndex = clip.items.firstIndex(where: { $0.id == oldItem.id }) ?? 0
                self.currentIndex.send(newIndex)
                self.loadPageAt.send(newIndex)
            }
            .store(in: &self.cancellableBag)

        self.changedPage
            .compactMap { [weak self] itemId in
                self?.items.value.firstIndex(where: { $0.id == itemId })
            }
            .sink { [weak self] index in
                self?.currentIndex.send(index)
            }
            .store(in: &self.cancellableBag)

        self.items
            .combineLatest(self.currentIndex)
            .sink { [weak self] items, index in
                guard items.indices.contains(index) else { return }
                self?.currentItem.send(items[index])
            }
            .store(in: &self.cancellableBag)
    }

    private func bindOutputs() {
        self.deleteClip
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteClips(having: [self.clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtDeleteClip)
                }
            }
            .store(in: &self.cancellableBag)

        self.removeClipItem
            .sink { [weak self] itemId in
                guard let self = self else { return }
                guard let item = self.items.value.first(where: { $0.identity == itemId }) else { return }
                if case let .failure(error) = self.clipCommandService.deleteClipItem(item) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    画像の削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send("\(L10n.clipCollectionErrorAtRemoveItemFromClip)\n\(error.makeErrorCode())")
                }
            }
            .store(in: &self.cancellableBag)

        self.replaceTags
            .sink { [weak self] tagIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clipId], byReplacingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    タグの更新に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtUpdateTagsToClip)
                }
            }
            .store(in: &self.cancellableBag)

        self.addToAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [self.clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムへの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.clipCollectionErrorAtAddClipToAlbum)
                }
            }
            .store(in: &self.cancellableBag)
    }

    func fetchImage() -> Data? {
        guard let item = self.currentItem.value else { return nil }
        do {
            return try self.imageQueryService.read(having: item.imageId)
        } catch {
            self.errorMessage.send(L10n.clipCollectionErrorAtShare)
            return nil
        }
    }

    func fetchImagesInClip() -> [Data] {
        do {
            return try self.items.value
                .map { $0.imageId }
                .compactMap { try self.imageQueryService.read(having: $0) }
        } catch {
            self.errorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
    }
}
