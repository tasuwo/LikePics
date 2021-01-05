//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagSelectionDelegate: AnyObject {
    func tagSelection(_ sender: AnyObject, didSelectTags tags: [Tag], withContext context: Any?)
}

public protocol TagSelectionViewModelType {
    var inputs: TagSelectionViewModelInputs { get }
    var outputs: TagSelectionViewModelOutputs { get }
}

public protocol TagSelectionViewModelInputs {
    var select: PassthroughSubject<Tag.Identity, Never> { get }
    var deselect: PassthroughSubject<Tag.Identity, Never> { get }
    var inputtedQuery: PassthroughSubject<String, Never> { get }
    var createdTag: PassthroughSubject<String, Never> { get }
    var done: PassthroughSubject<Void, Never> { get }
}

public protocol TagSelectionViewModelOutputs {
    var tags: CurrentValueSubject<[Tag], Never> { get }
    var selections: CurrentValueSubject<Set<Tag.Identity>, Never> { get }
    var filteredTags: CurrentValueSubject<[Tag], Never> { get }

    var displayCollectionView: CurrentValueSubject<Bool, Never> { get }
    var displayEmptyMessage: CurrentValueSubject<Bool, Never> { get }

    var errorMessage: PassthroughSubject<String, Never> { get }

    var close: PassthroughSubject<Void, Never> { get }

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
    public let done: PassthroughSubject<Void, Never> = .init()

    // MARK: TagSelectionViewModelOutputs

    public let tags: CurrentValueSubject<[Tag], Never> = .init([])
    public let selections: CurrentValueSubject<Set<Tag.Identity>, Never>
    public let filteredTags: CurrentValueSubject<[Tag], Never> = .init([])

    public let displayCollectionView: CurrentValueSubject<Bool, Never> = .init(false)
    public let displayEmptyMessage: CurrentValueSubject<Bool, Never> = .init(false)

    public let errorMessage: PassthroughSubject<String, Never> = .init()

    public let close: PassthroughSubject<Void, Never> = .init()

    public var selectedTags: [Tag] {
        return self.selections.value.compactMap { selection in
            self.tags.value.first(where: { $0.identity == selection })
        }
    }

    // MARK: Privates

    private let query: TagListQuery
    private let context: Any?
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private let searchQuery: CurrentValueSubject<String, Never> = .init("")
    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag = Set<AnyCancellable>()

    weak var delegate: TagSelectionDelegate?

    // MARK: - Lifecycle

    init(query: TagListQuery,
         selectedTags: [Tag.Identity],
         context: Any?,
         clipCommandService: ClipCommandServiceProtocol,
         settingStorage: UserSettingsStorageProtocol,
         logger: TBoxLoggable)
    {
        self.query = query
        self.context = context
        self.clipCommandService = clipCommandService
        self.settingStorage = settingStorage
        self.logger = logger
        self.selections = .init(Set(selectedTags))

        self.bind()
    }

    // MARK: - Methods

    private func bind() {
        self.query.tags
            .catch { _ in Just([]) }
            .combineLatest(self.searchQuery, self.settingStorage.showHiddenItems)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags, searchQuery, showHiddenItems in
                guard let self = self else { return }
                let tags = tags.filter { showHiddenItems ? true : $0.isHidden == false }
                self.filteredTags.send(self.searchStorage.perform(query: searchQuery, to: tags))
                self.tags.send(tags)
            }
            .store(in: &self.cancellableBag)

        self.createdTag
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

        self.done
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.tagSelection(self, didSelectTags: self.selectedTags, withContext: self.context)
                self.close.send(())
            }
            .store(in: &self.cancellableBag)
    }
}
