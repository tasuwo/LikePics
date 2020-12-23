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
    var select: PassthroughSubject<Tag.Identity, Never> { get }
    var deselect: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
    var createdTag: PassthroughSubject<String, Never> { get }
}

public protocol TagSelectionViewModelOutputs {
    var tags: CurrentValueSubject<[Tag], Never> { get }
    var selections: CurrentValueSubject<Set<Tag.Identity>, Never> { get }
    var filteredTags: CurrentValueSubject<[Tag], Never> { get }

    var displayCollectionView: CurrentValueSubject<Bool, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }

    var errorMessage: PassthroughSubject<String, Never> { get }

    var selectedTags: [Tag] { get }
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

    public let select: PassthroughSubject<Tag.Identity, Never> = .init()
    public let deselect: PassthroughSubject<Tag.Identity, Never> = .init()
    public let inputtedQuery: PassthroughSubject<String, Never> = .init()
    public let createdTag: PassthroughSubject<String, Never> = .init()

    // MARK: TagSelectionViewModelOutputs

    public let tags: CurrentValueSubject<[Tag], Never> = .init([])
    public let selections: CurrentValueSubject<Set<Tag.Identity>, Never>
    public let filteredTags: CurrentValueSubject<[Tag], Never> = .init([])

    public let displayCollectionView: CurrentValueSubject<Bool, Never> = .init(false)
    public let displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)

    public let errorMessage: PassthroughSubject<String, Never> = .init()

    public var selectedTags: [Tag] {
        return self.selections.value.compactMap { selection in
            self.tags.value.first(where: { $0.identity == selection })
        }
    }

    // MARK: Privates

    private let query: TagListQuery
    private let commandService: TagCommandServiceProtocol
    private let logger: TBoxLoggable
    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    public init(query: TagListQuery,
                selectedTags: Set<Tag.Identity>,
                commandService: TagCommandServiceProtocol,
                logger: TBoxLoggable)
    {
        self.query = query
        self.commandService = commandService
        self.logger = logger
        self.selections = .init(selectedTags)

        self.bind()
    }

    private func bind() {
        self.query.tags
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
            .combineLatest(self.inputtedQuery)
            .sink { [weak self] tags, query in
                guard let self = self else { return }

                self.searchStorage.updateCache(tags)
                let filteredTags = self.searchStorage.resolveTags(byQuery: query)
                    .sorted(by: { $0.name < $1.name })

                self.filteredTags.send(filteredTags)
                self.tags.send(tags)
            }
            .store(in: &self.cancellableBag)

        self.createdTag
            .sink { [weak self] name in
                guard let self = self else { return }
                guard case let .failure(error) = self.commandService.create(tagWithName: name) else { return }
                switch error {
                case .duplicated:
                    self.logger.write(ConsoleLog(level: .info, message: """
                    Duplicated tag name "\(name)".
                    """))
                    self.errorMessage.send(L10n.errorTagAddDuplicated)

                default:
                    self.logger.write(ConsoleLog(level: .error, message: """
                    Failed to add tag.
                    """))
                    self.errorMessage.send(L10n.errorTagAddDefault)
                }
            }
            .store(in: &self.cancellableBag)

        self.query.tags
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
            .map { $0.isEmpty }
            .sink { [weak self] isEmpty in
                self?.displayCollectionView.send(!isEmpty)
            }
            .store(in: &self.cancellableBag)

        self.query.tags
            .catch { _ in Just([]) }
            .eraseToAnyPublisher()
            .map { $0.isEmpty }
            .sink { [weak self] isEmpty in
                self?.displayEmptyMessage.send(isEmpty)
            }
            .store(in: &self.cancellableBag)

        self.select
            .sink { [weak self] tagId in
                guard let self = self else { return }
                self.selections.send(self.selections.value.union(Set([tagId])))
            }
            .store(in: &self.cancellableBag)

        self.deselect
            .sink { [weak self] tagId in
                guard let self = self else { return }
                self.selections.send(self.selections.value.subtracting(Set([tagId])))
            }
            .store(in: &self.cancellableBag)
    }
}
