//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagCollectionViewModelType {
    var inputs: TagCollectionViewModelInputs { get }
    var outputs: TagCollectionViewModelOutputs { get }
}

protocol TagCollectionViewModelInputs {
    var create: PassthroughSubject<String, Never> { get }
    var select: PassthroughSubject<Tag, Never> { get }
    var delete: PassthroughSubject<[Tag], Never> { get }
    var hide: PassthroughSubject<Tag.Identity, Never> { get }
    var reveal: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
    func updateTag(having id: Tag.Identity, nameTo name: String)
}

protocol TagCollectionViewModelOutputs {
    var items: AnyPublisher<[TagCollectionViewLayout.Item], Never> { get }

    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { get }
    var isEmptyMessageViewDisplaying: AnyPublisher<Bool, Never> { get }
    var isSearchBarEnabled: AnyPublisher<Bool, Never> { get }

    var displayErrorMessage: PassthroughSubject<String, Never> { get }
    var clearSearchBar: PassthroughSubject<Void, Never> { get }
    var presentTagsView: PassthroughSubject<Tag, Never> { get }
}

class TagCollectionViewModel: TagCollectionViewModelType,
    TagCollectionViewModelInputs,
    TagCollectionViewModelOutputs
{
    typealias Layout = TagCollectionViewLayout

    // MARK: - Properties

    // MARK: TagCollectionViewModelType

    var inputs: TagCollectionViewModelInputs { self }
    var outputs: TagCollectionViewModelOutputs { self }

    // MARK: TagCollectionViewModelInputs

    let create: PassthroughSubject<String, Never> = .init()
    let select: PassthroughSubject<Tag, Never> = .init()
    let delete: PassthroughSubject<[Tag], Never> = .init()
    let hide: PassthroughSubject<Tag.Identity, Never> = .init()
    let reveal: PassthroughSubject<Tag.Identity, Never> = .init()
    let inputtedQuery: PassthroughSubject<String, Never> = .init()

    // MARK: TagCollectionViewModelOutputs

    var items: AnyPublisher<[TagCollectionViewLayout.Item], Never> { _items.eraseToAnyPublisher() }

    var isCollectionViewDisplaying: AnyPublisher<Bool, Never> { _isCollectionViewDisplaying.eraseToAnyPublisher() }
    var isEmptyMessageViewDisplaying: AnyPublisher<Bool, Never> { _isEmptyMessageViewDisplaying.eraseToAnyPublisher() }
    var isSearchBarEnabled: AnyPublisher<Bool, Never> { _isSearchBarEnabled.eraseToAnyPublisher() }

    let displayErrorMessage: PassthroughSubject<String, Never> = .init()
    let clearSearchBar: PassthroughSubject<Void, Never> = .init()
    let presentTagsView: PassthroughSubject<Tag, Never> = .init()

    // MARK: Privates

    private let _tags: CurrentValueSubject<[Tag], Never>
    private let _items: CurrentValueSubject<[TagCollectionViewLayout.Item], Never>

    private let _isCollectionViewDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _isEmptyMessageViewDisplaying: CurrentValueSubject<Bool, Never> = .init(false)
    private let _isSearchBarEnabled: CurrentValueSubject<Bool, Never> = .init(false)

    private let query: TagListQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?

    private var searchStorage: SearchableTagsStorage = .init()
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(query: TagListQuery,
         clipCommandService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.clipCommandService = clipCommandService
        self.settingStorage = settingStorage
        self.logger = logger

        self._tags = .init(query.tags.value)
        self._items = .init([])

        self.bind()
    }

    // MARK: - Methods

    func bind() {
        self.query.tags
            .catch { _ in Just([]) }
            .combineLatest(self.inputtedQuery, self.settingStorage.showHiddenItems)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags, searchQuery, showHiddenItems in
                guard let self = self else { return }

                let tags = tags
                    .filter { showHiddenItems ? true : $0.isHidden == false }

                let filteredTags = self.searchStorage.perform(query: searchQuery, to: tags)
                let items: [Layout.Item] = (
                    [searchQuery.isEmpty ? .uncategorized : nil]
                        + filteredTags.map { .tag(Layout.Item.ListingTag(tag: $0, displayCount: showHiddenItems)) }
                ).compactMap { $0 }

                self._tags.send(tags)
                self._items.send(items)
            }
            .store(in: &self.subscriptions)

        self._tags
            .combineLatest(self.inputtedQuery)
            .sink { [weak self] tags, searchQuery in
                if tags.isEmpty, !searchQuery.isEmpty {
                    self?.clearSearchBar.send(())
                }
            }
            .store(in: &self.subscriptions)

        self._tags
            .map { $0.isEmpty }
            .sink { [weak self] isEmpty in
                guard let self = self else { return }
                if isEmpty {
                    self._isCollectionViewDisplaying.send(false)
                    self._isEmptyMessageViewDisplaying.send(true)
                    self._isSearchBarEnabled.send(false)
                } else {
                    self._isEmptyMessageViewDisplaying.send(false)
                    self._isCollectionViewDisplaying.send(true)
                    self._isSearchBarEnabled.send(true)
                }
            }
            .store(in: &self.subscriptions)

        self.create
            .sink { [weak self] name in
                guard let self = self else { return }
                guard case let .failure(error) = self.clipCommandService.create(tagWithName: name) else { return }
                switch error {
                case .duplicated:
                    self.logger.write(ConsoleLog(level: .info, message: """
                    Duplicated tag name "\(name)". (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.errorTagAddDuplicated)

                default:
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tag. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.errorTagAddDefault)
                }
            }
            .store(in: &self.subscriptions)

        self.select
            .sink { [weak self] tag in
                self?.presentTagsView.send(tag)
            }
            .store(in: &self.subscriptions)

        self.delete
            .sink { [weak self] tags in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteTags(having: tags.map({ $0.identity })) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete tags. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.errorTagDelete)
                    return
                }
            }
            .store(in: &self.subscriptions)

        self.hide
            .sink { [weak self] tagId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateTag(having: tagId, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to hide tags. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.errorTagDefault)
                    return
                }
            }
            .store(in: &self.subscriptions)

        self.reveal
            .sink { [weak self] tagId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateTag(having: tagId, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to reveal tags. (code: \(error.rawValue))
                    """))
                    self.displayErrorMessage.send(L10n.errorTagDefault)
                    return
                }
            }
            .store(in: &self.subscriptions)

        self.inputtedQuery.send("")
    }

    func updateTag(having id: Tag.Identity, nameTo name: String) {
        guard case let .failure(error) = self.clipCommandService.updateTag(having: id, nameTo: name) else { return }
        switch error {
        case .duplicated:
            self.logger.write(ConsoleLog(level: .info, message: """
            Duplicated tag name "\(name)". (code: \(error.rawValue))
            """))
            self.displayErrorMessage.send(L10n.errorTagRenameDuplicated)

        default:
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tag. (code: \(error.rawValue))
            """))
            self.displayErrorMessage.send(L10n.errorTagDefault)
        }
    }
}
