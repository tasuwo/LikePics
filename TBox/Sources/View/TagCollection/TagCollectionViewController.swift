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
    typealias Layout = TagCollectionViewLayout

    // MARK: - Properties

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
    private var dataSource: Layout.DataSource!
    private var collectionView: UICollectionView!
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: Components

    private let menuBuilder: TagCollectionMenuBuildable

    // MARK: States

    private let logger: TBoxLoggable
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: TagCollectionViewModel,
         menuBuilder: TagCollectionMenuBuildable,
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

        self.setupAppearance()
        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupSearchController()
        self.setupEmptyMessage()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.title = L10n.tagListViewTitle
        self.view.backgroundColor = Asset.Color.backgroundClient.color
    }

    private func startAddingTag() {
        self.addAlertContainer.present(
            withText: nil,
            on: self,
            validator: {
                $0?.isEmpty != true
            }, completion: { [weak self] action in
                guard case let .saved(text: tagName) = action else { return }
                self?.viewModel.inputs.create.send(tagName)
            }
        )
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.items
            .receive(on: DispatchQueue.global())
            .sink { [weak self] items in
                guard let self = self else { return }
                Layout.apply(items: items, to: self.dataSource, in: self.collectionView)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.isCollectionViewDisplaying
            .receive(on: DispatchQueue.main)
            .map { !$0 }
            .assign(to: \.isHidden, on: self.collectionView)
            .store(in: &self.subscriptions)
        dependency.outputs.isEmptyMessageViewDisplaying
            .receive(on: DispatchQueue.main)
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.subscriptions)
        dependency.outputs.isSearchBarEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.searchController.resignFirstResponder()
                self?.searchController.searchBar.isUserInteractionEnabled = isEnabled
                self?.searchController.searchBar.alpha = isEnabled ? 1.0 : 0.3
                if !isEnabled, self?.searchController.isActive == true {
                    self?.searchController.isActive = false
                }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.clearSearchBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.searchController.searchBar.resignFirstResponder()
                self?.searchController.searchBar.text = nil
            }
            .store(in: &self.subscriptions)

        dependency.outputs.displayErrorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.presentTagsView
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tag in
                guard let self = self else { return }
                guard let viewController = self.factory.makeSearchResultViewController(context: .tag(.categorized(tag))) else {
                    RootLogger.shared.write(ConsoleLog(level: .critical, message: "Failed to open SearchResultViewController."))
                    return
                }
                self.show(viewController, sender: nil)
            }
            .store(in: &self.subscriptions)
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView = UICollectionView(frame: self.view.frame,
                                               collectionViewLayout: Layout.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = .clear
        self.view.addSubview(collectionView)
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false

        self.dataSource = Layout.configureDataSource(collectionView: collectionView,
                                                     uncategorizedCellDelegate: self)
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

    // MARK: SearchController

    func setupSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = L10n.tagListViewPlaceholder
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
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
                self.viewModel.inputs.select.send(tag.tag)
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
                                              actionProvider: self.makeActionProvider(for: tag.tag, at: indexPath))

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

        case let .hide(immediately: immediately):
            return UIAction(title: L10n.tagListViewContextMenuActionHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                guard let self = self else { return }
                if immediately {
                    self.viewModel.inputs.hide.send(tag.id)
                } else {
                    // HACK: アイテム削除とContextMenuのドロップのアニメーションがコンフリクトするため、
                    //       アイテム削除を遅延させて自然なアニメーションにする
                    //       https://stackoverflow.com/a/57997005
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.viewModel.inputs.hide.send(tag.id)
                    }
                }
            }

        case .reveal:
            return UIAction(title: L10n.tagListViewContextMenuActionReveal,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                guard let self = self else { return }
                self.viewModel.inputs.reveal.send(tag.id)
            }

        case .delete:
            return UIAction(title: L10n.tagListViewContextMenuActionDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                guard let cell = self?.collectionView.cellForItem(at: indexPath) else { return }

                let alert = UIAlertController(title: nil,
                                              message: L10n.tagListViewAlertForDeleteMessage(tag.name),
                                              preferredStyle: .actionSheet)

                alert.addAction(.init(title: L10n.tagListViewAlertForDeleteAction, style: .destructive, handler: { _ in
                    self?.viewModel.inputs.delete.send([tag])
                }))
                alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

                alert.popoverPresentationController?.sourceView = self?.collectionView
                alert.popoverPresentationController?.sourceRect = cell.frame

                self?.present(alert, animated: true, completion: nil)
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
        let text = self.searchController.searchBar.text ?? ""
        self.viewModel.inputs.inputtedQuery.send(text)
    }

    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.viewModel.inputs.inputtedQuery.send(searchBar.text ?? "")
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
        let text = self.searchController.searchBar.text ?? ""
        self.viewModel.inputs.inputtedQuery.send(text)
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
