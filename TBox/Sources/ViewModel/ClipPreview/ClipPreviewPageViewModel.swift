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
    var pageChanged: PassthroughSubject<ClipItem.Identity, Never> { get }

    var deleteClip: PassthroughSubject<Void, Never> { get }
    var removeItem: PassthroughSubject<ClipItem.Identity, Never> { get }
    var replaceTags: PassthroughSubject<Set<Tag.Identity>, Never> { get }
    var addToAlbum: PassthroughSubject<Album.Identity, Never> { get }
}

protocol ClipPreviewPageViewModelOutputs {
    var clipId: Clip.Identity { get }

    var items: AnyPublisher<[ClipItem], Never> { get }
    var currentItem: AnyPublisher<ClipItem?, Never> { get }
    var currentItemIdValue: ClipItem.Identity { get }
    var tagIdsValue: [Tag.Identity] { get }

    var displayErrorMessage: PassthroughSubject<String, Never> { get }
    var reloadCurrentPage: PassthroughSubject<Void, Never> { get }
    var loadPage: PassthroughSubject<ClipItem.Identity, Never> { get }
    var close: PassthroughSubject<Void, Never> { get }

    func itemId(after: ClipItem.Identity) -> ClipItem.Identity?
    func itemId(before: ClipItem.Identity) -> ClipItem.Identity?

    func fetchImage() -> Data?
    func fetchImagesInClip() -> [Data]
}

class ClipPreviewPageViewModel: ClipPreviewPageViewModelType,
    ClipPreviewPageViewModelInputs,
    ClipPreviewPageViewModelOutputs
{
    struct ListingClipItem {
        let value: ClipItem
        let nextItemId: ClipItem.Identity?
        let previousItemId: ClipItem.Identity?
    }

    // MARK: - Properties

    // MARK: ClipPreviewPageViewModelType

    var inputs: ClipPreviewPageViewModelInputs { self }
    var outputs: ClipPreviewPageViewModelOutputs { self }

    // MARK: ClipPreviewPageViewModelInputs

    let pageChanged: PassthroughSubject<ClipItem.Identity, Never> = .init()

    let deleteClip: PassthroughSubject<Void, Never> = .init()
    let removeItem: PassthroughSubject<ClipItem.Identity, Never> = .init()
    let replaceTags: PassthroughSubject<Set<Tag.Identity>, Never> = .init()
    let addToAlbum: PassthroughSubject<Album.Identity, Never> = .init()

    // MARK: ClipPreviewPageViewModelOutputs

    let clipId: Clip.Identity

    var items: AnyPublisher<[ClipItem], Never> {
        _items.map { $0
            .map { $0.value.value }
            .sorted(by: { $0.clipIndex < $1.clipIndex })
        }
        .eraseToAnyPublisher()
    }

    var currentItem: AnyPublisher<ClipItem?, Never> {
        _currentItemId
            .map { self._items.value[$0] }
            .map { $0?.value }
            .eraseToAnyPublisher()
    }

    var currentItemIdValue: ClipItem.Identity { _currentItemId.value }
    var tagIdsValue: [Tag.Identity] { _tags.value.map({ $0.id }) }

    let displayErrorMessage: PassthroughSubject<String, Never> = .init()
    let reloadCurrentPage: PassthroughSubject<Void, Never> = .init()
    let loadPage: PassthroughSubject<Clip.Identity, Never> = .init()
    let close: PassthroughSubject<Void, Never> = .init()

    // MARK: Privates

    private let _items: CurrentValueSubject<[ClipItem.Identity: ListingClipItem], Never>
    private let _tags: CurrentValueSubject<[Tag], Never>
    private let _currentItemId: CurrentValueSubject<ClipItem.Identity, Never>

    private let query: ClipQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let previewLoader: PreviewLoaderProtocol
    private let imageQueryService: ImageQueryServiceProtocol
    private let logger: TBoxLoggable

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init?(clipId: Clip.Identity,
          query: ClipQuery,
          clipCommandService: ClipCommandServiceProtocol,
          previewLoader: PreviewLoaderProtocol,
          imageQueryService: ImageQueryServiceProtocol,
          logger: TBoxLoggable)
    {
        guard let firstItem = query.clip.value.items.first else { return nil }

        self.clipId = clipId
        self.query = query
        self.clipCommandService = clipCommandService
        self.previewLoader = previewLoader
        self.imageQueryService = imageQueryService
        self.logger = logger

        let listingItems = Self.makeListingClipItems(for: query.clip.value)
        self._items = .init(listingItems.reduce(into: [ClipItem.Identity: ListingClipItem]()) { $0[$1.value.id] = $1 })
        self._currentItemId = .init(firstItem.id)
        self._tags = .init(query.clip.value.tags)

        self.bind()
    }

    // MARK: - Methods

    private static func makeListingClipItems(for clip: Clip) -> [ListingClipItem] {
        var items: [ListingClipItem] = []

        for (index, item) in clip.items.enumerated() {
            items.append(.init(value: item,
                               nextItemId: clip.items.indices.contains(index + 1) ? clip.items[index + 1].id : nil,
                               previousItemId: clip.items.indices.contains(index - 1) ? clip.items[index - 1].id : nil))
        }

        return items
    }

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
                guard let firstItem = clip.items.first else {
                    self.close.send(())
                    return
                }

                let listingItems = Self.makeListingClipItems(for: clip)
                self._items.send(listingItems.reduce(into: [ClipItem.Identity: ListingClipItem]()) { $0[$1.value.id] = $1 })
                self._tags.send(clip.tags)

                // 元のItemが削除されているようであれば、最初のページをロードする
                if !clip.items.contains(where: { $0.id == self._currentItemId.value }) {
                    self._currentItemId.send(firstItem.id)
                    self.loadPage.send(self._currentItemId.value)
                } else {
                    self.reloadCurrentPage.send(())
                }
            }
            .store(in: &self.subscriptions)

        self.pageChanged
            .sink { [weak self] itemId in self?._currentItemId.send(itemId) }
            .store(in: &self.subscriptions)

        self._currentItemId
            .compactMap { [weak self] itemId in self?._items.value[itemId] }
            .sink { [weak self] item in self?.preloadPreviews(for: item) }
            .store(in: &self.subscriptions)
    }

    private func bindOutputs() {
        self.deleteClip
            .sink { [weak self] _ in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteClips(having: [self.clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    クリップの削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtDeleteClip)
                }
            }
            .store(in: &self.subscriptions)

        self.removeItem
            .sink { [weak self] itemId in
                guard let self = self else { return }
                guard let item = self._items.value[itemId]?.value else { return }
                if case let .failure(error) = self.clipCommandService.deleteClipItem(item) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    画像の削除に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send("\(L10n.clipCollectionErrorAtRemoveItemFromClip)\n\(error.makeErrorCode())")
                }
            }
            .store(in: &self.subscriptions)

        self.replaceTags
            .sink { [weak self] tagIds in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateClips(having: [self.clipId], byReplacingTagsHaving: Array(tagIds)) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    タグの更新に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtUpdateTagsToClip)
                }
            }
            .store(in: &self.subscriptions)

        self.addToAlbum
            .sink { [weak self] albumId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [self.clipId]) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    アルバムへの追加に失敗 (message: \(error.localizedDescription), code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.clipCollectionErrorAtAddClipToAlbum)
                }
            }
            .store(in: &self.subscriptions)
    }

    func itemId(after itemId: ClipItem.Identity) -> ClipItem.Identity? {
        return _items.value[itemId]?.nextItemId
    }

    func itemId(before itemId: ClipItem.Identity) -> ClipItem.Identity? {
        return _items.value[itemId]?.previousItemId
    }

    func fetchImage() -> Data? {
        guard let currentItem = self._items.value[self._currentItemId.value]?.value else { return nil }
        do {
            return try self.imageQueryService.read(having: currentItem.imageId)
        } catch {
            self.displayErrorMessage.send(L10n.clipCollectionErrorAtShare)
            return nil
        }
    }

    func fetchImagesInClip() -> [Data] {
        do {
            return try self._items.value.values
                .map { $0.value }
                .map { $0.imageId }
                .compactMap { try self.imageQueryService.read(having: $0) }
        } catch {
            self.displayErrorMessage.send(L10n.clipCollectionErrorAtShare)
            return []
        }
    }
}

// MARK: - Preload previews

extension ClipPreviewPageViewModel {
    private func preloadPreviews(for item: ListingClipItem) {
        self.reloadNextItems(8, from: item)
        self.reloadPreviousItems(8, from: item)
    }

    private func reloadNextItems(_ count: Int, from item: ListingClipItem) {
        let nextItem = { (clip: ListingClipItem) -> ListingClipItem? in
            guard let itemId = clip.nextItemId else { return nil }
            guard let item = self._items.value[itemId] else { return nil }
            return item
        }

        var currentItem: ListingClipItem = item
        for _ in 0 ..< count {
            guard let nextItem = nextItem(currentItem) else { return }
            currentItem = nextItem
            self.previewLoader.preloadPreview(itemId: currentItem.value.id,
                                              imageId: currentItem.value.imageId)
        }
    }

    private func reloadPreviousItems(_ count: Int, from item: ListingClipItem) {
        let prevItem = { (clip: ListingClipItem) -> ListingClipItem? in
            guard let itemId = clip.previousItemId else { return nil }
            guard let item = self._items.value[itemId] else { return nil }
            return item
        }

        var currentItem: ListingClipItem = item
        for _ in 0 ..< 8 {
            guard let prevItem = prevItem(currentItem) else { return }
            currentItem = prevItem
            self.previewLoader.preloadPreview(itemId: currentItem.value.id,
                                              imageId: currentItem.value.imageId)
        }
    }
}
