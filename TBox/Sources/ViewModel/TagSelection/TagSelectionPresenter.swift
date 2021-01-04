//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

protocol TagSelectionViewProtocol: AnyObject {
    func apply(_ tags: [Tag], isFiltered: Bool, isEmpty: Bool)
    func apply(selection: Set<Tag>)
    func showErrorMessage(_ message: String)
    func close()
}

// TODO: I/F を統合する
protocol TagSelectionPresenterDelegate: AnyObject {
    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?)
    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, tags: [Tag])
}

class TagSelectionPresenter {
    private let query: TagListQuery
    private let context: Any?
    private let clipCommandService: ClipCommandServiceProtocol
    private let settingStorage: UserSettingsStorageProtocol
    private let logger: TBoxLoggable

    private let searchQuery: CurrentValueSubject<String, Never> = .init("")
    private var searchStorage: SearchableTagsStorage = .init()
    private var cancellableBag = Set<AnyCancellable>()

    /// - attention: `setup()` 経由でのみ更新することを想定している
    private(set) var tags: [Tag] = [] {
        didSet {
            DispatchQueue.main.async {
                self.view?.apply(selection: Set(self.selectedTags))
            }
        }
    }

    private var selectedTags: [Tag] {
        return self.selections
            .compactMap { selection in
                return self.tags.first(where: { selection == $0.identity })
            }
    }

    private var selections: Set<Tag.Identity> {
        didSet {
            DispatchQueue.main.async {
                self.view?.apply(selection: Set(self.selectedTags))
            }
        }
    }

    weak var delegate: TagSelectionPresenterDelegate?
    weak var view: TagSelectionViewProtocol?

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
        self.selections = Set(selectedTags)
    }

    // MARK: - Methods

    func setup() {
        self.query.tags
            .catch { _ in Just([]) }
            .combineLatest(self.searchQuery, self.settingStorage.showHiddenItems)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags, searchQuery, showHiddenItems in
                guard let self = self else { return }
                let tags = tags
                    .filter { showHiddenItems ? true : $0.isHidden == false }
                let filteredTags = self.searchStorage.perform(query: searchQuery, to: tags)
                self.view?.apply(filteredTags, isFiltered: !searchQuery.isEmpty, isEmpty: tags.isEmpty)
                self.tags = tags
            }
            .store(in: &self.cancellableBag)
    }

    func addTag(_ name: String) {
        guard case let .failure(error) = self.clipCommandService.create(tagWithName: name) else { return }
        switch error {
        case .duplicated:
            self.logger.write(ConsoleLog(level: .info, message: """
            Duplicated tag name "\(name)". (code: \(error.rawValue))
            """))
            self.view?.showErrorMessage("\(L10n.errorTagAddDuplicated)\n\(error.makeErrorCode())")

        default:
            self.logger.write(ConsoleLog(level: .error, message: "Failed to add tag. (code: \(error.rawValue))"))
            self.view?.showErrorMessage("\(L10n.errorTagAddDefault)\n\(error.makeErrorCode())")
        }
    }

    func performSelection() {
        self.delegate?.tagSelectionPresenter(self, didSelectTagsHaving: self.selections, withContext: self.context)
        self.delegate?.tagSelectionPresenter(self, tags: self.selectedTags)
        self.view?.close()
    }

    func select(tagId: Tag.Identity) {
        self.selections.insert(tagId)
    }

    func deselect(tagId: Tag.Identity) {
        guard self.selections.contains(tagId) else { return }
        self.selections.remove(tagId)
    }

    func performQuery(_ query: String) {
        self.searchQuery.send(query)
    }
}
