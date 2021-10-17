//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Foundation

public protocol TagSelectionViewModelType {
    var inputs: TagSelectionViewModelInputs { get }
    var outputs: TagSelectionViewModelOutputs { get }
}

public protocol TagSelectionViewModelInputs {
    var create: PassthroughSubject<String, Never> { get }
    var select: PassthroughSubject<Tag.Identity, Never> { get }
    var deselect: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
}

public protocol TagSelectionViewModelOutputs {
    var tags: CurrentValueSubject<EntityCollectionSnapshot<Tag>, Never> { get }

    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { get }
    var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { get }

    var displayErrorMessage: PassthroughSubject<String, Never> { get }
}

public class TagSelectionViewModel: TagSelectionViewModelType,
    TagSelectionViewModelInputs,
    TagSelectionViewModelOutputs
{
    // MARK: - Properties

    // MARK: TagSelectionViewModelType

    public var inputs: TagSelectionViewModelInputs { self }
    public var outputs: TagSelectionViewModelOutputs { self }

    // MARK: TagSelectionViewModelInputs

    public let create: PassthroughSubject<String, Never> = .init()
    public let select: PassthroughSubject<Tag.Identity, Never> = .init()
    public let deselect: PassthroughSubject<Tag.Identity, Never> = .init()
    public let inputtedQuery: PassthroughSubject<String, Never> = .init()

    // MARK: TagSelectionViewModelOutputs

    public let tags: CurrentValueSubject<EntityCollectionSnapshot<Tag>, Never>

    public var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { _isCollectionViewDisplaying.eraseToAnyPublisher() }
    public var isEmptyMessageDisplaying: AnyPublisher<Bool, Never> { _isEmptyMessageDisplaying.eraseToAnyPublisher() }

    public let displayErrorMessage: PassthroughSubject<String, Never> = .init()

    // MARK: Privates

    private let _isCollectionViewDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _isEmptyMessageDisplaying: CurrentValueSubject<Bool, Never> = .init(false)

    private let query: TagListQuery
    private let commandService: TagCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: Loggable
    private var searchStorage: SearchableStorage<Tag> = .init()
    private var subscriptions: Set<AnyCancellable> = .init()
    private let tagsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBoxCore.TagSelectionViewModel", qos: .userInteractive)

    // MARK: - Lifecycle

    public init(query: TagListQuery,
                selectedTags: Set<Tag.Identity>,
                commandService: TagCommandServiceProtocol,
                settingStorage: UserSettingsStorageProtocol,
                logger: Loggable)
    {
        self.tags = .init(.init(entities: [], selectedIds: selectedTags, filteredIds: .init()))
        self.query = query
        self.commandService = commandService
        self.settingStorage = settingStorage
        self.logger = logger

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.query.tags
            .catch { _ in Just([]) }
            .combineLatest(self.inputtedQuery, self.settingStorage.showHiddenItems)
            .receive(on: tagsUpdateQueue)
            .sink { [weak self] tags, query, showHiddenItems in
                guard let self = self else { return }

                let filteringTags = tags.filter { showHiddenItems ? true : $0.isHidden == false }
                let filteredTagIds = self.searchStorage.perform(query: query, to: filteringTags).map { $0.id }

                let newTags = self.tags.value
                    .updated(entities: tags)
                    .updated(filteredIds: Set(filteredTagIds))
                self.tags.send(newTags)

                if filteringTags.isEmpty {
                    self._isCollectionViewDisplaying.send(false)
                    self._isEmptyMessageDisplaying.send(true)
                } else {
                    self._isEmptyMessageDisplaying.send(false)
                    self._isCollectionViewDisplaying.send(true)
                }
            }
            .store(in: &self.subscriptions)

        self.inputtedQuery.send("")

        self.create
            .sink { [weak self] name in
                guard let self = self else { return }
                switch self.commandService.create(tagWithName: name) {
                case let .success(tagId):
                    let newTags = self.tags.value.updated(selectedIds: self.tags.value._selectedIds.union(Set([tagId])))
                    self.tags.send(newTags)

                case .failure(.duplicated):
                    self.logger.write(ConsoleLog(level: .info, message: "Duplicated tag name \(name)."))
                    self.displayErrorMessage.send(L10n.errorTagAddDuplicated)

                default:
                    self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag."))
                    self.displayErrorMessage.send(L10n.errorTagAddDefault)
                }
            }
            .store(in: &self.subscriptions)

        self.select
            .sink { [weak self] tagId in
                guard let self = self else { return }
                let newTags = self.tags.value.updated(selectedIds: self.tags.value._selectedIds.union(Set([tagId])))
                self.tags.send(newTags)
            }
            .store(in: &self.subscriptions)

        self.deselect
            .sink { [weak self] tagId in
                guard let self = self else { return }
                let newTags = self.tags.value.updated(selectedIds: self.tags.value._selectedIds.subtracting(Set([tagId])))
                self.tags.send(newTags)
            }
            .store(in: &self.subscriptions)
    }
}
