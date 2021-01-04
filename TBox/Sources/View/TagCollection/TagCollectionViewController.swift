//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

class TagCollectionViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = TagCollectionViewModelType

    enum Section: Int {
        case uncategorized
        case main
    }

    enum Item: Hashable {
        case uncategorized
        case tag(Tag)
    }

    // MARK: - Properties

    private static let uncategorizedCellIdentifier = "uncategorized"

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: View

    private let emptyMessageView = EmptyMessageView()
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
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    @IBOutlet var collectionView: TagCollectionView!
    @IBOutlet var searchBar: UISearchBar!

    // MARK: Components

    private let menuBuilder: TagCollectionMenuBuildable.Type

    // MARK: States

    private let logger: TBoxLoggable
    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: TagCollectionViewModel,
         menuBuilder: TagCollectionMenuBuildable.Type,
         logger: TBoxLoggable)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.menuBuilder = menuBuilder
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // HACK: nibから読み込んでいるため初期サイズがnibに引きずられる
        //       これによりCollectionViewのレイアウトが初回表示時にズレるのを防ぐ
        self.view.frame = self.tabBarController?.view.frame ?? self.view.frame

        self.setupCollectionView()
        self.setupAppearance()
        self.setupNavigationBar()
        self.setupSearchBar()
        self.setupEmptyMessage()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.title = L10n.tagListViewTitle
    }

    private func startAddingTag() {
        self.addAlertContainer.present(
            withText: nil,
            on: self,
            validator: {
                $0?.isEmpty != true
            }, completion: { [weak self] action in
                guard case let .saved(text: tagName) = action else { return }
                self?.viewModel.inputs.created.send(tagName)
            }
        )
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.filteredTags
            .combineLatest(dependency.outputs.displayUncategorizedTag)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags, displayUncategorizedTag in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.uncategorized])
                snapshot.appendItems(displayUncategorizedTag ? [.uncategorized] : [])
                snapshot.appendSections([.main])
                snapshot.appendItems(tags.map { .tag($0) })
                self?.dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.displaySearchBar
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .map { !$0 }
            .assign(to: \.isHidden, on: self.searchBar)
            .store(in: &self.cancellableBag)
        dependency.outputs.displayCollectionView
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .map { !$0 }
            .assign(to: \.isHidden, on: self.collectionView)
            .store(in: &self.cancellableBag)
        dependency.outputs.displayEmptyMessageView
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)
        dependency.outputs.displayClipCount
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] displayClipCount in
                self?.collectionView.visibleCells
                    .compactMap { $0 as? TagCollectionViewCell }
                    .forEach { $0.visibleCountIfPossible = displayClipCount }
                self?.collectionView.collectionViewLayout.invalidateLayout()
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.searchBarCleared
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.searchBar.resignFirstResponder()
                self?.searchBar.text = nil
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.tagViewOpened
            .sink { [weak self] tag in
                guard let self = self else { return }
                guard let viewController = self.factory.makeSearchResultViewController(context: .tag(.categorized(tag))) else {
                    RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open SearchResultViewController."))
                    return
                }
                self.show(viewController, sender: nil)
            }
            .store(in: &self.cancellableBag)
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color
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
                let configuration = TagCollectionView.CellConfiguration.Tag(
                    tag: tag,
                    displayMode: self.isEditing ? .deletion : .normal,
                    visibleDeleteButton: false,
                    visibleCountIfPossible: self.viewModel.outputs.displayClipCount.value,
                    delegate: nil
                )
                return TagCollectionView.provideCell(collectionView: collectionView,
                                                     indexPath: indexPath,
                                                     configuration: .tag(configuration))

            case .uncategorized:
                let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.uncategorizedCellIdentifier, for: indexPath)
                guard let cell = dequeuedCell as? UncategorizedCell else { return dequeuedCell }
                cell.delegate = self
                return cell
            }
        }
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        self.navigationItem.leftBarButtonItem = addItem
    }

    @objc
    func didTapAdd() {
        self.startAddingTag()
    }

    // MARK: SearchBar

    func setupSearchBar() {
        self.searchBar.delegate = self
        self.searchBar.showsCancelButton = false
    }

    // MARK: EmptyMessage

    private func setupEmptyMessage() {
        self.view.addSubview(self.emptyMessageView)
        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(self.emptyMessageView.constraints(fittingIn: self.view.safeAreaLayoutGuide))

        self.emptyMessageView.title = L10n.tagListViewEmptyTitle
        self.emptyMessageView.message = L10n.tagListViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.tagListViewEmptyActionTitle
        self.emptyMessageView.delegate = self

        self.emptyMessageView.alpha = 0
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
        case let .tag(tag):
            if !self.isEditing {
                self.viewModel.inputs.selected.send(tag)
            }

        case .uncategorized:
            print(#function)

        case .none:
            break
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
                                              actionProvider: self.makeActionProvider(for: tag, at: indexPath))

        default:
            return nil
        }
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration, collectionView: UICollectionView) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? NSIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: identifier as IndexPath) else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell, parameters: parameters)
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
                            image: UIImage(systemName: "square.on.square.fill")) { _ in
                UIPasteboard.general.string = tag.name
            }

        case .hide:
            return UIAction(title: L10n.tagListViewContextMenuActionHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.viewModel.inputs.hided.send(tag.id)
                }
            }

        case .reveal:
            return UIAction(title: L10n.tagListViewContextMenuActionReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.viewModel.inputs.revealed.send(tag.id)
                }
            }

        case .delete:
            return UIAction(title: L10n.tagListViewContextMenuActionDelete,
                            image: UIImage(systemName: "trash.fill")) { [weak self] _ in
                self?.viewModel.inputs.deleted.send([tag])
            }

        case .rename:
            return UIAction(title: L10n.tagListViewContextMenuActionUpdate,
                            image: UIImage(systemName: "text.cursor")) { [weak self] _ in
                guard let self = self else { return }
                self.updateAlertContainer.present(
                    withText: tag.name,
                    on: self,
                    validator: {
                        $0 != tag.name && $0?.isEmpty != true
                    }, completion: { action in
                        guard case let .saved(text: name) = action else { return }
                        self.viewModel.inputs.updateTag(having: tag.identity, nameTo: name)
                    }
                )
            }
        }
    }
}

extension TagCollectionViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.viewModel.inputs.inputtedQuery.send(text)
        }
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.viewModel.inputs.inputtedQuery.send(text)
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

extension TagCollectionViewController: UncategorizedCellDelegate {
    // MARK: - UncategorizedCellDelegate

    func didTap(_ cell: UncategorizedCell) {
        guard let viewController = self.factory.makeSearchResultViewController(context: .tag(.uncategorized)) else {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open SearchResultViewController."))
            return
        }
        self.show(viewController, sender: nil)
    }
}

extension TagCollectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingTag()
    }
}
