//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

public protocol TagSelectionViewModelType {
    var inputs: TagSelectionViewModelInputs { get }
    var outputs: TagSelectionViewModelOutputs { get }
}

public protocol TagSelectionViewModelInputs {
    var dataSourceUpdated: PassthroughSubject<Void, Never> { get }

    var create: PassthroughSubject<String, Never> { get }
    var select: PassthroughSubject<Tag.Identity, Never> { get }
    var deselect: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
}

public protocol TagSelectionViewModelOutputs {
    var tags: AnyPublisher<[Tag], Never> { get }

    var selectedTagsValue: [Tag] { get }

    var selected: PassthroughSubject<Set<Tag>, Never> { get }
    var deselected: PassthroughSubject<Set<Tag>, Never> { get }

    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { get }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { get }

    var displayErrorMessage: PassthroughSubject<String, Never> { get }
}

public class TagSelectionViewModel: TagSelectionViewModelType,
    TagSelectionViewModelInputs,
    TagSelectionViewModelOutputs
{
    struct OrderedTag {
        let index: Int
        let value: Tag
    }

    // MARK: - Properties

    // MARK: TagSelectionViewModelType

    public var inputs: TagSelectionViewModelInputs { self }
    public var outputs: TagSelectionViewModelOutputs { self }

    // MARK: TagSelectionViewModelInputs

    public let dataSourceUpdated: PassthroughSubject<Void, Never> = .init()

    public let create: PassthroughSubject<String, Never> = .init()
    public let select: PassthroughSubject<Tag.Identity, Never> = .init()
    public let deselect: PassthroughSubject<Tag.Identity, Never> = .init()
    public let inputtedQuery: PassthroughSubject<String, Never> = .init()

    // MARK: TagSelectionViewModelOutputs

    public var tags: AnyPublisher<[Tag], Never> {
        _filteredTagIds.map { $0
            .compactMap { [weak self] id in self?._tags.value[id] }
            .map { $0.value }
        }
        .eraseToAnyPublisher()
    }

    public var selectedTagsValue: [Tag] {
        _selections.value
            .compactMap { _tags.value[$0] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    public let selected: PassthroughSubject<Set<Tag>, Never> = .init()
    public let deselected: PassthroughSubject<Set<Tag>, Never> = .init()

    public var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { _isCollectionViewDisplaying.eraseToAnyPublisher() }
    public var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { _isEmptyMessageDisplaying.eraseToAnyPublisher() }

    public let displayErrorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private let _tags: CurrentValueSubject<[Tag.Identity: OrderedTag], Never> = .init([:])
    private let _selections: CurrentValueSubject<Set<Tag.Identity>, Never> = .init([])
    private let _filteredTagIds: CurrentValueSubject<[Tag.Identity], Never> = .init([])
    private let _creatingTagName: CurrentValueSubject<String?, Never> = .init(nil)

    private let _isCollectionViewDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _isEmptyMessageDisplaying: CurrentValueSubject<Bool, Never> = .init(false)

    private let query: TagListQuery
    private let commandService: TagCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: Loggable
    private var searchStorage: SearchableStorage<Tag> = .init()
    private var subscriptions: Set<AnyCancellable> = .init()
    private let tagsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBoxCore.TagSelectionViewModel", qos: .userInteractive)

    private let initialSelections: Set<Tag.Identity>

    // MARK: - Lifecycle

    public init(query: TagListQuery,
                selectedTags: Set<Tag.Identity>,
                commandService: TagCommandServiceProtocol,
                settingStorage: UserSettingsStorageProtocol,
                logger: Loggable)
    {
        self.query = query
        self.commandService = commandService
        self.settingStorage = settingStorage
        self.logger = logger

        self.initialSelections = selectedTags

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.dataSourceUpdated
            .prefix(1)
            .sink { [weak self] in
                guard let self = self else { return }
                self._selections.send(self.initialSelections)
                self.selected.send(Set(self.selectedTagsValue))
            }
            .store(in: &self.subscriptions)

        self.query.tags
            .catch { _ in Just([]) }
            .combineLatest(self.inputtedQuery, self.settingStorage.showHiddenItems)
            .receive(on: tagsUpdateQueue)
            .sink { [weak self] tags, query, showHiddenItems in
                guard let self = self else { return }

                let orderedTags = tags.enumerated().reduce(into: [Tag.Identity: OrderedTag]()) { dict, value in
                    dict[value.element.id] = OrderedTag(index: value.offset, value: value.element)
                }

                let filteringTags = tags.filter { showHiddenItems ? true : $0.isHidden == false }
                let filteredTagIds = self.searchStorage.perform(query: query, to: filteringTags).map { $0.id }

                if filteringTags.isEmpty {
                    self._isCollectionViewDisplaying.send(false)
                    self._isEmptyMessageDisplaying.send(true)
                } else {
                    self._isEmptyMessageDisplaying.send(false)
                    self._isCollectionViewDisplaying.send(true)
                }

                self._tags.send(orderedTags)
                self._filteredTagIds.send(filteredTagIds)
            }
            .store(in: &self.subscriptions)

        self.query.tags
            .catch { _ in Just([]) }
            // HACK: CollectionViewへの反映を待ってから選択する必要があるため、若干遅延させる
            .delay(for: 0.1, scheduler: DispatchQueue.global())
            .sink { [weak self] tags in
                guard let self = self else { return }
                if let creatingTagName = self._creatingTagName.value,
                   let createdTag = tags.first(where: { $0.name == creatingTagName })
                {
                    self.select.send(createdTag.id)
                    self._creatingTagName.send(nil)
                }
            }
            .store(in: &self.subscriptions)

        self.inputtedQuery.send("")

        self.create
            .sink { [weak self] name in
                guard let self = self else { return }
                self._creatingTagName.send(name)
                guard case let .failure(error) = self.commandService.create(tagWithName: name) else { return }
                switch error {
                case .duplicated:
                    self.logger.write(ConsoleLog(level: .info, message: """
                    Duplicated tag name "\(name)".
                    """))
                    self.displayErrorMessage.send(L10n.errorTagAddDuplicated)
                    self._creatingTagName.send(nil)

                default:
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tag.
                    """))
                    self.displayErrorMessage.send(L10n.errorTagAddDefault)
                    self._creatingTagName.send(nil)
                }
            }
            .store(in: &self.subscriptions)

        self.select
            .sink { [weak self] tagId in
                guard let self = self, let tag = self._tags.value[tagId]?.value else { return }
                self._selections.send(self._selections.value.union(Set([tagId])))
                self.selected.send(Set([tag]))
            }
            .store(in: &self.subscriptions)

        self.deselect
            .sink { [weak self] tagId in
                guard let self = self, let tag = self._tags.value[tagId]?.value else { return }
                self._selections.send(self._selections.value.subtracting(Set([tagId])))
                self.deselected.send(Set([tag]))
            }
            .store(in: &self.subscriptions)
    }
}
