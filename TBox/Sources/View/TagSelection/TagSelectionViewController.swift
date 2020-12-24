//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

class TagSelectionViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: TagSelectionPresenter
    private let emptyMessageView = EmptyMessageView()
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                             message: L10n.tagListViewAlertForAddMessage,
                             placeholder: L10n.tagListViewAlertForAddPlaceholder)
    )

    private var dataSource: UICollectionViewDiffableDataSource<Section, Tag>!

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: TagCollectionView!

    // MARK: - Lifecycle

    init(factory: Factory, presenter: TagSelectionPresenter) {
        self.factory = factory
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // HACK: nibから読み込んでいるため初期サイズがnibに引きずられる
        //       これによりCollectionViewのレイアウトが初回表示時にズレるのを防ぐ
        self.view.frame = self.navigationController?.view.frame ?? self.view.frame

        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupSearchBar()
        self.setupEmptyMessage()

        self.presenter.setup()
    }

    // MARK: - Methods

    private func startAddingTag() {
        self.alertContainer.present(
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

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.dataSource = .init(collectionView: self.collectionView, cellProvider: self.cellProvider())
    }

    private func cellProvider() -> (UICollectionView, IndexPath, Tag) -> UICollectionViewCell? {
        return { collectionView, indexPath, item -> UICollectionViewCell? in
            let configuration = TagCollectionView.CellConfiguration.Tag(tag: item,
                                                                        displayMode: .checkAtSelect,
                                                                        visibleDeleteButton: false,
                                                                        delegate: nil)
            return TagCollectionView.provideCell(collectionView: collectionView,
                                                 indexPath: indexPath,
                                                 configuration: .tag(configuration))
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection? in
            let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil,
                                                                 top: nil,
                                                                 trailing: nil,
                                                                 bottom: .fixed(4))
            let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
            return section
        }
        return layout
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.tagSelectionViewTitle

        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.didTapSave))

        self.navigationItem.leftBarButtonItem = addItem
        self.navigationItem.rightBarButtonItem = saveItem
    }

    @objc
    func didTapAdd() {
        self.startAddingTag()
    }

    @objc
    func didTapSave() {
        self.presenter.performSelection()
    }

    // MARK: SearchBar

    private func setupSearchBar() {
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

extension TagSelectionViewController: TagSelectionViewProtocol {
    // MARK: - TagSelectionViewProtocol

    func apply(_ tags: [Tag], isFiltered: Bool, isEmpty: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
        snapshot.appendSections([.main])
        snapshot.appendItems(tags)

        if !isEmpty {
            self.searchBar.isHidden = false
            self.collectionView.isHidden = false
            self.emptyMessageView.alpha = 0
        }
        self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            guard isEmpty else { return }
            self?.searchBar.isHidden = true
            self?.collectionView.isHidden = true
            UIView.animate(withDuration: 0.2) {
                self?.emptyMessageView.alpha = 1
            }
            self?.searchBar.resignFirstResponder()
            self?.searchBar.text = nil
            self?.presenter.performQuery("")
        }
    }

    func apply(selection: Set<Tag>) {
        let indexPaths = selection
            .compactMap { self.dataSource.indexPath(for: $0) }
        self.collectionView.applySelection(at: indexPaths)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension TagSelectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagId = self.dataSource.itemIdentifier(for: indexPath)?.identity else { return }
        self.presenter.select(tagId: tagId)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let tagId = self.dataSource.itemIdentifier(for: indexPath)?.identity else { return }
        self.presenter.deselect(tagId: tagId)
    }
}

extension TagSelectionViewController: UISearchBarDelegate {
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

extension TagSelectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingTag()
    }
}
