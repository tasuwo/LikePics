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
    private var cancellableBag: Set<AnyCancellable> = .init()

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
            self?.viewModel.inputs.createdTag.send(tag)
        }
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.tags
            .filter { $0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.searchBar.resignFirstResponder()
                self?.searchBar.text = nil
                self?.viewModel.inputs.inputtedQuery.send("")
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.displayCollectionView
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.isHidden, on: self.searchBar)
            .store(in: &self.cancellableBag)
        dependency.outputs.displayCollectionView
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assignNoRetain(to: \.isHidden, on: self.collectionView)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayEmptyMessage
            .receive(on: DispatchQueue.main)
            .map { $0 ? 1 : 0 }
            .assignNoRetain(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.filteredTags
            .combineLatest(dependency.outputs.selections)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags, selections in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
                snapshot.appendSections([.main])
                snapshot.appendItems(tags)
                self?.dataSource.apply(snapshot, animatingDifferences: true)

                DispatchQueue.main.async {
                    let indexPaths = selections
                        .compactMap { identity in dependency.outputs.tags.value.first(where: { $0.identity == identity }) }
                        .compactMap { [weak self] item in self?.dataSource.indexPath(for: item) }
                    self?.collectionView.applySelection(at: indexPaths)
                }
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
            self.delegate?.didSelectTags(tags: self.viewModel.outputs.selectedTags)
        }
    }

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView.collectionViewLayout = self.createLayout()
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
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
        RunLoop.main.perform { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.viewModel.inputs.inputtedQuery.send(text)
        }
    }

    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let text = self?.searchBar.text else { return }
            self?.viewModel.inputs.inputtedQuery.send(text)
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
