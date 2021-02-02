//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

class AlbumSelectionViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = AlbumSelectionViewModelType
    typealias Layout = AlbumSelectionViewLayout

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: AlbumSelectionViewModel

    // MARK: View

    private let emptyMessageView = EmptyMessageView()
    private lazy var alertContainer = TextEditAlert(
        configuration: .init(title: L10n.albumListViewAlertForAddTitle,
                             message: L10n.albumListViewAlertForAddMessage,
                             placeholder: L10n.albumListViewAlertForAddPlaceholder)
    )
    private var dataSource: Layout.DataSource!

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: UICollectionView!

    // MARK: Thumbnail

    private let thumbnailLoader: ThumbnailLoader

    // MARK: States

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: AlbumSelectionViewModel,
         thumbnailLoader: ThumbnailLoader)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.thumbnailLoader = thumbnailLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureCollectionView()
        self.setupNavigationBar()
        self.setupSearchBar()
        self.setupEmptyMessage()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    private func startAddingAlbum() {
        self.alertContainer.present(
            withText: nil,
            on: self,
            validator: {
                $0?.isEmpty != true
            }, completion: { [weak self] action in
                guard case let .saved(text: text) = action else { return }
                self?.viewModel.addedAlbum.send(text)
            }
        )
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.albums
            .receive(on: DispatchQueue.global())
            .sink { [weak self] albums in
                var snapshot = Layout.Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(albums)
                self?.dataSource.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.displayEmptyMessage
            .receive(on: DispatchQueue.main)
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.subscriptions)

        dependency.outputs.close
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.dismiss(animated: true, completion: nil) }
            .store(in: &self.subscriptions)
    }

    // MARK: CollectionView

    private func configureCollectionView() {
        collectionView.setCollectionViewLayout(Layout.createLayout(), animated: false)

        collectionView.delegate = self

        let dataSource = Layout.createDataSource(collectionView: collectionView,
                                                 thumbnailLoader: thumbnailLoader)
        self.dataSource = dataSource
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.albumSelectionViewTitle
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                                target: self,
                                                                action: #selector(self.didTapAdd))
    }

    @objc
    func didTapAdd() {
        self.startAddingAlbum()
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

        self.emptyMessageView.title = L10n.albumListViewEmptyTitle
        self.emptyMessageView.message = L10n.albumListViewEmptyMessage
        self.emptyMessageView.actionButtonTitle = L10n.albumListViewEmptyActionTitle
        self.emptyMessageView.delegate = self

        self.emptyMessageView.alpha = 0
    }
}

extension AlbumSelectionViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let album = self.dataSource.itemIdentifier(for: indexPath) else { return }
        self.viewModel.inputs.selectedAlbum.send(album.id)
    }
}

extension AlbumSelectionViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    func didTapActionButton(_ view: EmptyMessageView) {
        self.startAddingAlbum()
    }
}

extension AlbumSelectionViewController: UISearchBarDelegate {
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
