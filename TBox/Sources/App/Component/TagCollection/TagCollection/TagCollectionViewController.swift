//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit
import TBoxUIKit
import UIKit

class TagCollectionViewController: UIViewController {
    typealias Layout = TagCollectionViewLayout
    typealias TagCollectionViewStore = Store<TagCollectionViewState, TagCollectionViewAction, TagCollectionViewDependency>

    // MARK: - Properties

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private let emptyMessageView = EmptyMessageView()
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: Component

    private let tagAdditionAlert: TextEditAlertController
    private let tagEditAlert: TextEditAlertController

    // MARK: Service

    private let menuBuilder: TagCollectionMenuBuildable

    // MARK: Store

    private var store: TagCollectionViewStore
    private var subscriptions: Set<AnyCancellable> = .init()
    private let collectionUpdateQueue = DispatchQueue(label: "net.tasuwo.TBox.TagCollectionViewController")

    // MARK: - Initializers

    init(state: TagCollectionViewState,
         tagAdditionAlertState: TextEditAlertState,
         tagEditAlertState: TextEditAlertState,
         dependency: TagCollectionViewDependency,
         menuBuilder: TagCollectionMenuBuildable)
    {
        self.store = TagCollectionViewStore(initialState: state, dependency: dependency, reducer: TagCollectionViewReducer())
        self.tagAdditionAlert = .init(state: tagAdditionAlertState)
        self.tagEditAlert = .init(state: tagEditAlertState)

        self.menuBuilder = menuBuilder

        super.init(nibName: nil, bundle: nil)

        tagAdditionAlert.textEditAlertDelegate = self
        tagEditAlert.textEditAlertDelegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.tagListViewTitle

        configureViewHierarchy()
        configureDataSource()
        configureNavigationBar()
        configureSearchController()
        configureEmptyMessageView()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateUserActivity(store.stateValue)
    }
}

// MARK: - Bind

extension TagCollectionViewController {
    private func bind(to store: TagCollectionViewStore) {
        store.state
            .receive(on: collectionUpdateQueue)
            .sink { [weak self] state in self?.applySnapshot(for: state) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: collectionView)
            .store(in: &subscriptions)
        store.state
            .bind(\.emptyMessageViewAlpha, to: \.alpha, on: emptyMessageView)
            .store(in: &subscriptions)

        store.state
            .bind(\.isSearchBarEnabled) { [searchController] isEnabled in
                searchController.set(isEnabled: isEnabled)
            }
            .store(in: &subscriptions)
        store.state
            .bind(\.searchQuery) { [searchController] query in
                searchController.set(text: query)
            }
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.alert)
            .sink { [weak self] state in self?.presentAlertIfNeeded(for: state) }
            .store(in: &subscriptions)

        store.state
            .receive(on: DispatchQueue.global())
            .removeDuplicates()
            .debounce(for: 3, scheduler: DispatchQueue.global())
            .sink { [weak self] state in self?.updateUserActivity(state) }
            .store(in: &subscriptions)
    }

    // MARK: Snapshot

    private func applySnapshot(for state: TagCollectionViewState) {
        var items: [Layout.Item?] = []

        items += state.searchQuery.isEmpty ? [.uncategorized] : [nil]
        items += state.tags.orderedFilteredEntities()
            .map { .tag(Layout.Item.ListingTag(tag: $0, displayCount: !state.isSomeItemsHidden)) }

        Layout.apply(items: items.compactMap({ $0 }), to: dataSource, in: collectionView)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for state: TagCollectionViewState) {
        switch state.alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .addition:
            tagAdditionAlert.present(with: "", validator: { $0?.isEmpty == false }, on: self)

        case let .edit(tagId: _, name: name):
            tagEditAlert.present(with: name, validator: { $0?.isEmpty == false && $0 != name }, on: self)

        case let .deletion(tagId: tagId, tagName: name):
            presentDeleteConfirmationAlert(for: tagId, tagName: name, state: state)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }

    private func presentDeleteConfirmationAlert(for tagId: Tag.Identity, tagName: String, state: TagCollectionViewState) {
        guard let tag = state.tags.entity(having: tagId),
              let indexPath = dataSource.indexPath(for: .tag(.init(tag: tag, displayCount: !state.isSomeItemsHidden))),
              let cell = collectionView.cellForItem(at: indexPath)
        else {
            store.execute(.alertDismissed)
            return
        }

        let alert = UIAlertController(title: nil,
                                      message: L10n.tagListViewAlertForDeleteMessage(tagName),
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.tagListViewAlertForDeleteAction, style: .destructive, handler: { [weak self] _ in
            self?.store.execute(.alertDeleteConfirmTapped)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: { [weak self] _ in
            self?.store.execute(.alertDismissed)
        }))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        present(alert, animated: true, completion: nil)
    }

    // MARK: User Activity

    private func updateUserActivity(_ state: TagCollectionViewState) {
        DispatchQueue.global().async {
            let encoder = JSONEncoder()
            guard let data = try? encoder.encode(Intent.seeTagCollection(state.removingSessionStates())),
                  let string = String(data: data, encoding: .utf8) else { return }
            DispatchQueue.main.async {
                self.view.window?.windowScene?.userActivity = NSUserActivity.make(with: string)
            }
        }
    }
}

// MARK: - Configuration

extension TagCollectionViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.backgroundClient.color

        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view))

        emptyMessageView.alpha = 0
        view.addSubview(self.emptyMessageView)
        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))
    }

    private func configureDataSource() {
        collectionView.delegate = self
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        dataSource = Layout.configureDataSource(collectionView: collectionView,
                                                uncategorizedCellDelegate: self)
    }

    private func configureNavigationBar() {
        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction { [weak self] _ in
            self?.store.execute(.tagAdditionButtonTapped)
        })
        self.navigationItem.leftBarButtonItem = addItem
    }

    private func configureSearchController() {
        // イベント発火を避けるためにdelegate設定前にリストアする必要がある
        searchController.searchBar.text = store.stateValue.searchQuery

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.placeholderSearchTag
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func configureEmptyMessageView() {
        self.emptyMessageView.title = L10n.tagListViewEmptyTitle
        self.emptyMessageView.message = L10n.tagListViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.tagListViewEmptyActionTitle
        self.emptyMessageView.delegate = self
    }
}

extension TagCollectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch self.dataSource.itemIdentifier(for: indexPath) {
        case let .tag(listingTag):
            store.execute(.select(listingTag.tag))

        default: () // NOP
        }
    }
}

extension TagCollectionViewController {
    // MARK: - UICollectionViewDelegate (Context Menu)

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch self.dataSource.itemIdentifier(for: indexPath) {
        case let .tag(tag):
            return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                              previewProvider: nil,
                                              actionProvider: self.makeActionProvider(for: tag.tag, at: indexPath))

        default:
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return UITargetedPreview.create(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return UITargetedPreview.create(for: configuration, collectionView: collectionView)
    }

    private func makeActionProvider(for tag: Tag, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        let items = self.menuBuilder.build(for: tag).map {
            self.makeAction(from: $0, for: tag, at: indexPath)
        }
        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeAction(from item: TagCollection.MenuItem, for tag: Tag, at indexPath: IndexPath) -> UIAction {
        switch item {
        case .copy:
            return UIAction(title: L10n.tagListViewContextMenuActionCopy,
                            image: UIImage(systemName: "square.on.square.fill")) { [weak self] _ in
                self?.store.execute(.copyMenuSelected(tag))
            }

        case .hide:
            return UIAction(title: L10n.tagListViewContextMenuActionHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                self?.store.execute(.hideMenuSelected(tag))
            }

        case .reveal:
            return UIAction(title: L10n.tagListViewContextMenuActionReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                self?.store.execute(.revealMenuSelected(tag))
            }

        case .delete:
            return UIAction(title: L10n.tagListViewContextMenuActionDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                self?.store.execute(.deleteMenuSelected(tag))
            }

        case .rename:
            return UIAction(title: L10n.tagListViewContextMenuActionUpdate,
                            image: UIImage(systemName: "text.cursor")) { [weak self] _ in
                self?.store.execute(.renameMenuSelected(tag))
            }
        }
    }
}

extension TagCollectionViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.store.execute(.searchQueryChanged(searchBar.text ?? ""))
            }
        }
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.resignFirstResponder()
    }
}

extension TagCollectionViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating

    func updateSearchResults(for searchController: UISearchController) {
        store.execute(.searchQueryChanged(searchController.searchBar.text ?? ""))
    }
}

extension TagCollectionViewController: UncategorizedCellDelegate {
    // MARK: - UncategorizedCellDelegate

    func didTap(_ cell: UncategorizedCell) {
        store.execute(.uncategorizedTagButtonTapped)
    }
}

extension TagCollectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.emptyMessageViewActionButtonTapped)
    }
}

extension TagCollectionViewController: TextEditAlertDelegate {
    // MARK: - TextEditAlertDelegate

    func textEditAlert(_ id: UUID, didTapSaveWithText text: String) {
        store.execute(.alertSaveButtonTapped(text: text))
    }

    func textEditAlertDidCancel(_ id: UUID) {
        store.execute(.alertDismissed)
    }
}
