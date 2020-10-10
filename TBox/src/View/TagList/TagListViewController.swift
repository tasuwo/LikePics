//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class TagListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section: Int {
        case uncategorized
        case main
    }

    enum Item: Hashable {
        case uncategorized
        case tag(Tag)
    }

    private static let uncategorizedCellIdentifier = "uncategorized"

    private let factory: Factory
    private let presenter: TagListPresenter
    private let logger: TBoxLoggable
    private lazy var addAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                             message: L10n.tagListViewAlertForAddMessage,
                             placeholder: L10n.tagListViewAlertForAddPlaceholder)
    )
    private lazy var updateAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.tagListViewAlertForUpdateTitle,
                             message: L10n.tagListViewAlertForUpdateMessage,
                             placeholder: L10n.tagListViewAlertForUpdatePlaceholder)
    )
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    @IBOutlet var collectionView: TagCollectionView!
    @IBOutlet var searchBar: UISearchBar!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: TagListPresenter, logger: TBoxLoggable) {
        self.factory = factory
        self.presenter = presenter
        self.logger = logger
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()
        self.setupAppearance()
        self.updateNavigationBar(for: self.isEditing)
        self.setupSearchBar()

        self.presenter.setup()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.title = L10n.tagListViewTitle
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false

        self.collectionView.register(UncategorizedCell.nib,
                                     forCellWithReuseIdentifier: Self.uncategorizedCellIdentifier)

        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.cellProvider())
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .uncategorized:
                return self.createUncategorizedLayoutSection()

            case .main:
                return self.createTagsLayoutSection()

            case .none:
                return nil
            }
        }
        return layout
    }

    private func createUncategorizedLayoutSection() -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                                            heightDimension: .fractionalHeight(1.0)))

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(40))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)

        return NSCollectionLayoutSection(group: group)
    }

    private func createTagsLayoutSection() -> NSCollectionLayoutSection {
        let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil,
                                                             top: nil,
                                                             trailing: nil,
                                                             bottom: .fixed(4))
        let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
        return section
    }

    private func cellProvider() -> (UICollectionView, IndexPath, Item) -> UICollectionViewCell? {
        return { [weak self] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return nil }
            switch item {
            case let .tag(tag):
                return TagCollectionView.cellProvider(dataSource: self)(collectionView, indexPath, tag)

            case .uncategorized:
                let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.uncategorizedCellIdentifier, for: indexPath)
                guard let cell = dequeuedCell as? UncategorizedCell else { return dequeuedCell }
                cell.delegate = self
                return cell
            }
        }
    }

    // MARK: NavigationBar

    private func updateNavigationBar(for isEditing: Bool) {
        if isEditing {
            let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.didTapCancel))
            let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didTapDone))
            self.navigationItem.leftBarButtonItem = cancelItem
            self.navigationItem.rightBarButtonItem = doneItem
        } else {
            let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
            let deleteItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapDelete))
            self.navigationItem.leftBarButtonItem = addItem
            self.navigationItem.rightBarButtonItem = deleteItem
        }
    }

    @objc
    func didTapAdd() {
        self.addAlertContainer.present(
            withText: nil,
            on: self,
            validator: {
                $0?.isEmpty != true
            }, completion: { [weak self] action in
                guard case let .saved(text: tag) = action else { return }
                self?.presenter.addTag(tag)
            }
        )
    }

    @objc
    func didTapDone() {
        guard let count = self.collectionView.indexPathsForSelectedItems?.count else {
            self.logger.write(ConsoleLog(level: .error, message: "Invalid done action occurred."))
            return
        }

        let alert = UIAlertController(title: nil,
                                      message: L10n.tagListViewAlertForDeleteMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.tagListViewAlertForDeleteAction(count), style: .destructive, handler: { [weak self] _ in
            guard let self = self, let indices = self.collectionView.indexPathsForSelectedItems else { return }
            let selectedTags = indices
                .compactMap { (index: IndexPath) -> Item? in self.dataSource.itemIdentifier(for: index) }
                .compactMap { (item: Item) -> Tag? in
                    if case let .tag(tag) = item { return tag } else { return nil }
                }
            self.presenter.delete(selectedTags)
        }))
        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    @objc
    func didTapCancel() {
        self.setEditing(false, animated: true)
    }

    @objc
    func didTapDelete() {
        self.setEditing(true, animated: true)
    }

    // MARK: SearchBar

    func setupSearchBar() {
        self.searchBar.delegate = self
        self.searchBar.showsCancelButton = false
    }

    // MARK: UIViewController (Override)

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.updateNavigationBar(for: editing)

        self.collectionView
            .visibleCells
            .map { $0 as? TagCollectionViewCell }
            .forEach { $0?.displayMode = editing ? .deletion : .normal }
        self.collectionView
            .indexPathsForSelectedItems?
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
        self.collectionView.allowsMultipleSelection = editing
    }
}

extension TagListViewController: TagListViewProtocol {
    // MARK: - TagListViewProtocol

    func apply(_ tags: [Tag], isFiltered: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.uncategorized])
        snapshot.appendItems(isFiltered ? [] : [.uncategorized])
        snapshot.appendSections([.main])
        snapshot.appendItems(tags.map { .tag($0) })
        self.dataSource.apply(snapshot)
    }

    func search(with context: SearchContext) {
        guard let viewController = self.factory.makeSearchResultViewController(context: context) else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open SearchResultViewController."))
            return
        }
        self.show(viewController, sender: nil)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func endEditing() {
        self.setEditing(false, animated: true)
    }
}

extension TagListViewController: TagCollectionViewDataSource {
    // MARK: - TagCollectionViewDataSource

    func displayMode(_ collectionView: UICollectionView) -> TagCollectionViewCell.DisplayMode {
        return self.isEditing ? .deletion : .normal
    }
}

extension TagListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch self.dataSource.itemIdentifier(for: indexPath) {
        case let .tag(tag):
            if !self.isEditing {
                self.presenter.select(tag)
            }

        case .uncategorized:
            print(#function)

        case .none:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch self.dataSource.itemIdentifier(for: indexPath) {
        case let .tag(tag):
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: self.makeActionProvider(for: tag))

        default:
            return nil
        }
    }

    private func makeActionProvider(for tag: Tag) -> UIContextMenuActionProvider {
        let copy = UIAction(title: L10n.tagListViewContextMenuActionCopy,
                            image: UIImage(systemName: "square.on.square.fill")) { _ in
            UIPasteboard.general.string = tag.name
        }
        let delete = UIAction(title: L10n.tagListViewContextMenuActionDelete,
                              image: UIImage(systemName: "square.and.arrow.up.fill")) { [weak self] _ in
            self?.presenter.delete([tag])
        }
        let update = UIAction(title: L10n.tagListViewContextMenuActionUpdate,
                              image: UIImage(systemName: "text.cursor")) { [weak self] _ in
            guard let self = self else { return }
            self.updateAlertContainer.present(
                withText: tag.name,
                on: self,
                validator: {
                    $0 != tag.name && $0?.isEmpty != true
                }, completion: { action in
                    guard case let .saved(text: name) = action else { return }
                    self.presenter.updateTag(having: tag.identity, nameTo: name)
                }
            )
        }
        return { (elements: [UIMenuElement]) in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [copy, delete, update])
        }
    }
}

extension TagListViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.presenter.performQuery(text)
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.presenter.performQuery(text)
        }
        return true
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
}

extension TagListViewController: UncategorizedCellDelegate {
    // MARK: - UncategorizedCellDelegate

    func didTap(_ cell: UncategorizedCell) {
        guard let viewController = self.factory.makeSearchResultViewController(context: .uncategorized) else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open SearchResultViewController."))
            return
        }
        self.show(viewController, sender: nil)
    }
}
