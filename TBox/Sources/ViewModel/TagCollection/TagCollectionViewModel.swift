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
    var created: PassthroughSubject<String, Never> { get }
    var selected: PassthroughSubject<Tag, Never> { get }
    var deleted: PassthroughSubject<[Tag], Never> { get }
    var hided: PassthroughSubject<Tag.Identity, Never> { get }
    var revealed: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
    func updateTag(having id: Tag.Identity, nameTo name: String)
}

protocol TagCollectionViewModelOutputs {
    var tags: CurrentValueSubject<[Tag], Never> { get }
    var filteredTags: CurrentValueSubject<[Tag], Never> { get }

    var displayUncategorizedTag: CurrentValueSubject<Bool, Never> { get }
    var displaySearchBar: CurrentValueSubject<Bool, Never> { get }
    var displayCollectionView: CurrentValueSubject<Bool, Never> { get }
    var displayEmptyMessageView: CurrentValueSubject<Bool, Never> { get }
    var displayClipCount: CurrentValueSubject<Bool, Never> { get }

    var errorMessage: PassthroughSubject<String, Never> { get }
    var searchBarCleared: PassthroughSubject<Void, Never> { get }
    var tagViewOpened: PassthroughSubject<Tag, Never> { get }
}

class TagCollectionViewModel: TagCollectionViewModelType,
    TagCollectionViewModelInputs,
    TagCollectionViewModelOutputs
{
    // MARK: - Properties

    // MARK: TagCollectionViewModelType

    var inputs: TagCollectionViewModelInputs { self }
    var outputs: TagCollectionViewModelOutputs { self }

    // MARK: TagCollectionViewModelInputs

    let created: PassthroughSubject<String, Never> = .init()
    let selected: PassthroughSubject<Tag, Never> = .init()
    let deleted: PassthroughSubject<[Tag], Never> = .init()
    let hided: PassthroughSubject<Tag.Identity, Never> = .init()
    let revealed: PassthroughSubject<Tag.Identity, Never> = .init()
    let inputtedQuery: PassthroughSubject<String, Never> = .init()

    // MARK: TagCollectionViewModelOutputs

    let tags: CurrentValueSubject<[Tag], Never> = .init([])
    let filteredTags: CurrentValueSubject<[Tag], Never> = .init([])

    let displayUncategorizedTag: CurrentValueSubject<Bool, Never> = .init(false)
    let displaySearchBar: CurrentValueSubject<Bool, Never> = .init(false)
    let displayCollectionView: CurrentValueSubject<Bool, Never> = .init(false)
    let displayEmptyMessageView: CurrentValueSubject<Bool, Never> = .init(false)
    let displayClipCount: CurrentValueSubject<Bool, Never> = .init(false)

    let errorMessage: PassthroughSubject<String, Never> = .init()
    let searchBarCleared: PassthroughSubject<Void, Never> = .init()
    let tagViewOpened: PassthroughSubject<Tag, Never> = .init()

    // MARK: Privates

    private let query: TagListQuery
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private var cancellable: AnyCancellable?

    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag = Set<AnyCancellable>()

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

                self.displayEmptyMessageView.send(tags.isEmpty)
                self.displaySearchBar.send(!tags.isEmpty)
                self.displayCollectionView.send(!tags.isEmpty)
                self.displayEmptyMessageView.send(tags.isEmpty)
                self.displayUncategorizedTag.send(searchQuery.isEmpty && !tags.isEmpty)

                if tags.isEmpty {
                    self.searchBarCleared.send(())
                }

                if tags.isEmpty, !searchQuery.isEmpty {
                    self.inputtedQuery.send("")
                }

                self.filteredTags.send(self.searchStorage.perform(query: searchQuery, to: tags))
                self.tags.send(tags)
            }
            .store(in: &self.cancellableBag)

        self.settingStorage.showHiddenItems
            .sink { [weak self] showHiddenItems in self?.displayClipCount.send(showHiddenItems) }
            .store(in: &self.cancellableBag)

        self.created
            .sink { [weak self] name in
                guard let self = self else { return }
                guard case let .failure(error) = self.clipCommandService.create(tagWithName: name) else { return }
                switch error {
                case .duplicated:
                    self.logger.write(ConsoleLog(level: .info, message: """
                    Duplicated tag name "\(name)". (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.errorTagAddDuplicated)

                default:
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tag. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.errorTagAddDefault)
                }
            }
            .store(in: &self.cancellableBag)

        self.selected
            .sink { [weak self] tag in
                self?.tagViewOpened.send(tag)
            }
            .store(in: &self.cancellableBag)

        self.deleted
            .sink { [weak self] tags in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.deleteTags(having: tags.map({ $0.identity })) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to delete tags. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.errorTagDelete)
                    return
                }
            }
            .store(in: &self.cancellableBag)

        self.hided
            .sink { [weak self] tagId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateTag(having: tagId, byHiding: true) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to hide tags. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.errorTagDefault)
                    return
                }
            }
            .store(in: &self.cancellableBag)

        self.revealed
            .sink { [weak self] tagId in
                guard let self = self else { return }
                if case let .failure(error) = self.clipCommandService.updateTag(having: tagId, byHiding: false) {
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to reveal tags. (code: \(error.rawValue))
                    """))
                    self.errorMessage.send(L10n.errorTagDefault)
                    return
                }
            }
            .store(in: &self.cancellableBag)

        self.inputtedQuery.send("")
    }

    func updateTag(having id: Tag.Identity, nameTo name: String) {
        guard case let .failure(error) = self.clipCommandService.updateTag(having: id, nameTo: name) else { return }
        switch error {
        case .duplicated:
            self.logger.write(ConsoleLog(level: .info, message: """
            Duplicated tag name "\(name)". (code: \(error.rawValue))
            """))
            self.errorMessage.send(L10n.errorTagRenameDuplicated)

        default:
            self.logger.write(ConsoleLog(level: .error, message: """
            Failed to add tag. (code: \(error.rawValue))
            """))
            self.errorMessage.send(L10n.errorTagDefault)
        }
    }
}
