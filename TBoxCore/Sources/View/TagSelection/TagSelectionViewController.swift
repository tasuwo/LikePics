//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

public protocol TagSelectionViewControllerDelegate: AnyObject {
    func didSelectTags(tags: [Tag])
}

public class TagSelectionViewController: UIViewController {
    typealias Dependency = TagSelectionViewModelType

    enum Section {
        case main
    }

    private let viewModel: TagSelectionViewModelType
    private let emptyMessageView = EmptyMessageView()
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                             message: L10n.tagListViewAlertForAddMessage,
                             placeholder: L10n.tagListViewAlertForAddPlaceholder)
    )

    private var dataSource: UICollectionViewDiffableDataSource<Section, Tag>!
    private var subscriptions: Set<AnyCancellable> = .init()

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: TagCollectionView!

    private weak var delegate: TagSelectionViewControllerDelegate?

    // MARK: - Lifecycle

    public init(viewModel: TagSelectionViewModelType,
                delegate: TagSelectionViewControllerDelegate)
    {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: "TagSelectionViewController", bundle: Bundle(for: Self.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        // HACK: nibから読み込んでいるため初期サイズがnibに引きずられる
        //       これによりCollectionViewのレイアウトが初回表示時にズレるのを防ぐ
        self.view.frame = self.navigationController?.view.frame ?? self.view.frame
        self.view.backgroundColor = Asset.Color.background.color

        self.setupNavigationBar()
        self.setupCollectionView()
        self.setupSearchBar()
        self.setupEmptyMessage()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func startAddingTag() {
        self.alertContainer.present(withText: nil, on: self) {
            $0?.isEmpty != true
        } completion: { [weak self] action in
            guard case let .saved(text: tag) = action else { return }
            self?.viewModel.inputs.create.send(tag)
        }
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.isCollectionViewDisplaying
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.isHidden, on: self.searchBar)
            .store(in: &self.subscriptions)
        dependency.outputs.isCollectionViewDisplaying
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.isHidden, on: self.collectionView)
            .store(in: &self.subscriptions)

        dependency.outputs.isEmptyMessageDisplaying
            .receive(on: DispatchQueue.main)
            .map { $0 ? 1 : 0 }
            .assignNoRetain(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.subscriptions)

        dependency.outputs.selected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selected in
                guard let self = self else { return }
                selected
                    .compactMap { self.dataSource.indexPath(for: $0) }
                    .forEach { self.collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.deselected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deselected in
                guard let self = self else { return }
                deselected
                    .compactMap { self.dataSource.indexPath(for: $0) }
                    .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.tags
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
                snapshot.appendSections([.main])
                snapshot.appendItems(tags)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
                self?.viewModel.inputs.dataSourceUpdated.send(())
            }
            .store(in: &self.subscriptions)

        dependency.outputs.displayErrorMessage
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.tagSelectionViewTitle

        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didTapDone))

        self.navigationItem.leftBarButtonItems = [addItem]
        self.navigationItem.rightBarButtonItems = [saveItem]
    }

    @objc
    func didTapAdd() {
        self.startAddingTag()
    }

    @objc
    func didTapDone() {
        self.dismiss(animated: true) {
            self.delegate?.didSelectTags(tags: self.viewModel.outputs.selectedTagsValue)
        }
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.collectionView.backgroundColor = Asset.Color.background.color
        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: self.cellProvider())
    }

    private func cellProvider() -> (UICollectionView, IndexPath, Tag) -> UICollectionViewCell? {
        return { collectionView, indexPath, item -> UICollectionViewCell? in
            let configuration = TagCollectionView.CellConfiguration.Tag(tag: item,
                                                                        displayMode: .checkAtSelect,
                                                                        visibleDeleteButton: false,
                                                                        visibleCountIfPossible: true,
                                                                        delegate: nil)
            return TagCollectionView.provideCell(collectionView: collectionView,
                                                 indexPath: indexPath,
                                                 configuration: .tag(configuration))
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection? in
            let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: nil, bottom: .fixed(4))
            let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
            return section
        }
        return layout
    }

    // MARK: SearchBar

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        searchBar.placeholder = L10n.placeholderSearchTag
        searchBar.backgroundColor = Asset.Color.background.color
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

extension TagSelectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tagId = self.dataSource.itemIdentifier(for: indexPath)?.identity else { return }
        self.viewModel.inputs.select.send(tagId)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let tagId = self.dataSource.itemIdentifier(for: indexPath)?.identity else { return }
        self.viewModel.inputs.deselect.send(tagId)
    }
}

extension TagSelectionViewController: UISearchBarDelegate {
    // MARK: - UISearchBarDelegate

    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        RunLoop.main.perform {
            self.viewModel.inputs.inputtedQuery.send(searchBar.text ?? "")
        }
    }

    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // HACK: marked text 入力を待つために遅延を設ける
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            RunLoop.main.perform {
                self.viewModel.inputs.inputtedQuery.send(searchBar.text ?? "")
            }
        }
        return true
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(true, animated: true)
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar.setShowsCancelButton(false, animated: true)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
}

extension TagSelectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingTag()
    }
}
