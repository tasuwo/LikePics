//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import UIKit

protocol ClipEditViewModelType {
    var inputs: ClipEditViewModelInputs { get }
    var outputs: ClipEditViewModelOutputs { get }
}

protocol ClipEditViewModelInputs {
    func hideClip()
    func revealClip()
    func replaceTagsOfClip(_ tagIds: Set<Tag.Identity>)
    func removeTagFromClip(_ tagId: Tag.Identity)
    func delete(itemAt index: Int) -> Bool
    func update(isHidden: Bool)
    func update(siteUrl: URL?, forItem: ClipItem.Identity)
    func reordered(_ snapshot: ClipEditViewLayout.Snapshot)
    func deleteClip()
}

protocol ClipEditViewModelOutputs {
    var applySnapshot: AnyPublisher<ClipEditViewLayout.Snapshot, Never> { get }
    var applyDeletions: PassthroughSubject<[ClipEditViewLayout.Item], Never> { get }

    var tags: [Tag] { get }
    var isItemDeletable: Bool { get }

    var close: PassthroughSubject<Void, Never> { get }
    var displayErrorMessage: PassthroughSubject<String, Never> { get }
}

class ClipEditViewModel: ClipEditViewModelType,
    ClipEditViewModelInputs,
    ClipEditViewModelOutputs
{
    typealias Layout = ClipEditViewLayout

    // MARK: - Properties

    // MARK: ClipEditViewModelType

    var inputs: ClipEditViewModelInputs { self }
    var outputs: ClipEditViewModelOutputs { self }

    // MARK: ClipEditViewModelOutputs

    var applySnapshot: AnyPublisher<Layout.Snapshot, Never> { _snapshot.eraseToAnyPublisher() }
    let applyDeletions: PassthroughSubject<[Layout.Item], Never> = .init()

    var tags: [Tag] { _tags }
    var isItemDeletable: Bool { _items.count > 1 }

    let close: PassthroughSubject<Void, Never> = .init()
    let displayErrorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Inner Model

    private var _snapshot: CurrentValueSubject<Layout.Snapshot, Never>

    // MARK: Source of truth

    private var _clip: Clip
    private var _tags: [Tag]
    private var _items: [ClipItem]

    // MARK: Privates

    private let clipQuery: ClipQuery
    private let itemListQuery: ClipItemListQuery
    private let tagListQuery: TagListQuery
    private let commandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol

    private let queue = DispatchQueue(label: "net.tasuwo.ClipEditViewModel")
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init?(id: Clip.Identity,
          clipQueryService: ClipQueryServiceProtocol,
          clipCommandService: ClipCommandServiceProtocol,
          settingStorage: UserSettingsStorageProtocol,
          logger: TBoxLoggable)
    {
        let clipQuery: ClipQuery
        switch clipQueryService.queryClip(having: id) {
        case let .success(result):
            clipQuery = result

        case let .failure(error):
            logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize ClipEditViewModel. (\(error.rawValue))
            """))
            return nil
        }

        let itemListQuery: ClipItemListQuery
        switch clipQueryService.queryClipItems(inClipHaving: id) {
        case let .success(result):
            itemListQuery = result

        case let .failure(error):
            logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize ClipEditViewModel. (\(error.rawValue))
            """))
            return nil
        }

        let tagListQuery: TagListQuery
        switch clipQueryService.queryTags(forClipHaving: id) {
        case let .success(result):
            tagListQuery = result

        case let .failure(error):
            logger.write(ConsoleLog(level: .error, message: """
            Failed to initialize ClipEditViewModel. (\(error.rawValue))
            """))
            return nil
        }

        self.clipQuery = clipQuery
        self.itemListQuery = itemListQuery
        self.tagListQuery = tagListQuery
        self.commandService = clipCommandService
        self.settingStorage = settingStorage

        let clip = clipQuery.clip.value
        let items = itemListQuery.items.value
        let tags = tagListQuery.tags.value
        self._clip = clip
        self._tags = tags
        self._items = items
        self._snapshot = .init(Self.createSnapshot(clip: clip,
                                                   items: items,
                                                   tags: tags,
                                                   hidingItems: !settingStorage.readShowHiddenItems()))

        self.bind()
    }

    func createSnapshot(clip: Clip, items: [ClipItem], tags: [Tag]) -> ClipEditViewLayout.Snapshot {
        Self.createSnapshot(clip: clip,
                            items: items,
                            tags: tags,
                            hidingItems: !settingStorage.readShowHiddenItems())
    }

    private static func createSnapshot(clip: Clip, items: [ClipItem], tags: [Tag], hidingItems: Bool) -> ClipEditViewLayout.Snapshot {
        var snapshot = ClipEditViewLayout.Snapshot()
        snapshot.appendSections([.tag])
        let tags = tags
            .compactMap { tag in hidingItems ? (tag.isHidden ? nil : tag) : tag }
            .map { ClipEditViewLayout.Item.tag($0) }
        snapshot.appendItems([.tagAddition] + tags)

        snapshot.appendSections([.meta])
        let dataSize = ByteCountFormatter.string(fromByteCount: Int64(clip.dataSize), countStyle: .binary)
        snapshot.appendItems([
            .meta(.init(title: L10n.clipEditViewHiddenTitle, accessory: .switch(isOn: clip.isHidden))),
            .meta(.init(title: L10n.clipEditViewClipDataSizeTitle, accessory: .label(title: dataSize)))
        ])

        snapshot.appendSections([.clipItem])
        snapshot.appendItems(items
            .map({ $0.converted() })
            .map({ ClipEditViewLayout.Item.clipItem($0) }))

        snapshot.appendSections([.footer])
        snapshot.appendItems([.deleteClip])

        return snapshot
    }
}

extension ClipEditViewModel {
    private func bind() {
        clipQuery.clip
            .filter { [weak self] clip in
                guard let self = self else { return false }
                return clip.id != self._clip.id
                    || clip.items != self._clip.items
                    || clip.dataSize != self._clip.dataSize
                    || clip.isHidden != self._clip.isHidden
            }
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] clip in
                guard let self = self else { return }
                self._clip = clip
                self._snapshot.send(self.createSnapshot(clip: clip, items: self._items, tags: self._tags))
            }
            .store(in: &subscriptions)

        itemListQuery.items
            .filter { [weak self] items in
                guard let self = self else { return false }
                return items != self._items
            }
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] items in
                guard let self = self else { return }
                self._items = items
                self._snapshot.send(self.createSnapshot(clip: self._clip, items: items, tags: self._tags))
            }
            .store(in: &subscriptions)

        tagListQuery.tags
            .filter { [weak self] tags in
                guard let self = self else { return false }
                return tags != self._tags
            }
            .receive(on: queue)
            .sink { [weak self] _ in
                self?.close.send(())
            } receiveValue: { [weak self] tags in
                guard let self = self else { return }
                self._tags = tags
                self._snapshot.send(self.createSnapshot(clip: self._clip, items: self._items, tags: tags))
            }
            .store(in: &subscriptions)

        settingStorage.showHiddenItems
            .receive(on: queue)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self._snapshot.send(self.createSnapshot(clip: self._clip, items: self._items, tags: self._tags))
            }
            .store(in: &subscriptions)
    }
}

extension ClipEditViewModel {
    // MARK: ClipEditViewModelInputs

    func hideClip() {
        if case .failure = commandService.updateClips(having: [_clip.id], byHiding: true) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }

    func revealClip() {
        if case .failure = commandService.updateClips(having: [_clip.id], byHiding: false) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }

    func replaceTagsOfClip(_ tagIds: Set<Tag.Identity>) {
        if case .failure = commandService.updateClips(having: [_clip.id], byReplacingTagsHaving: Array(tagIds)) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }

    func removeTagFromClip(_ tagId: Tag.Identity) {
        if case .failure = commandService.updateClips(having: [_clip.id], byDeletingTagsHaving: [tagId]) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }

    func delete(itemAt index: Int) -> Bool {
        guard _items.indices.contains(index) else { return false }

        let snapshot = _items
        let removingItem = _items.remove(at: index)

        guard case .success = commandService.deleteClipItem(removingItem) else {
            displayErrorMessage.send(L10n.failedToUpdateClip)
            _items = snapshot
            return false
        }

        let removedItem = removingItem.converted()
        applyDeletions.send([.clipItem(removedItem)])

        return true
    }

    func update(isHidden: Bool) {
        if case .failure = commandService.updateClips(having: [_clip.id], byHiding: isHidden) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }

    func update(siteUrl: URL?, forItem itemId: ClipItem.Identity) {
        if case .failure = commandService.updateClipItems(having: [itemId], byUpdatingSiteUrl: siteUrl) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }

    func reordered(_ snapshot: ClipEditViewLayout.Snapshot) {
        let orderedItems = snapshot.itemIdentifiers
            .compactMap { item -> Layout.ClipItem? in
                switch item {
                case let .clipItem(value):
                    return value

                default:
                    return nil
                }
            }

        _items = orderedItems.compactMap { item in
            _items.first(where: { $0.id == item.itemId })
        }
        _snapshot.send(self.createSnapshot(clip: _clip, items: _items, tags: _tags))

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            if case .failure = self.commandService.updateClip(having: self._clip.id, byReorderingItemsHaving: orderedItems.map({ $0.itemId })) {
                self.displayErrorMessage.send(L10n.failedToUpdateClip)
            }
        }
    }

    func deleteClip() {
        if case .failure = commandService.deleteClips(having: [_clip.id]) {
            displayErrorMessage.send(L10n.failedToUpdateClip)
        }
    }
}

private extension ClipItem {
    func converted() -> ClipEditViewLayout.ClipItem {
        return ClipEditViewLayout.ClipItem(itemId: self.id,
                                           imageId: self.imageId,
                                           imageUrl: self.imageUrl,
                                           siteUrl: self.url,
                                           dataSize: Double(self.imageDataSize),
                                           imageHeight: self.imageSize.height,
                                           imageWidth: self.imageSize.width)
    }
}
