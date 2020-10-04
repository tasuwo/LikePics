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
    private lazy var alertContainer = AddingAlert(configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                                                                       message: L10n.tagListViewAlertForAddMessage,
                                                                       placeholder: L10n.tagListViewAlertForAddPlaceholder),
                                                  baseView: self)

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Tag>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var collectionView: TagCollectionView!

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

        self.setupCollectionView()
        self.setupNavigationBar()

        self.presenter.setup()
    }

    // MARK: - Methods

    // MARK: Collection View

    private func setupCollectionView() {
        self.collectionView = TagCollectionView(frame: self.view.bounds,
                                                collectionViewLayout: self.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = true
        self.dataSource = .init(collectionView: self.collectionView,
                                cellProvider: TagCollectionView.cellProvider(dataSource: self))
    }

    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, _ -> NSCollectionLayoutSection? in
            return TagCollectionView.createLayoutSection()
        }
        return layout
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationItem.title = "タグを選択"

        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAdd))
        let saveItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.didTapSave))

        self.navigationItem.leftBarButtonItem = addItem
        self.navigationItem.rightBarButtonItem = saveItem
    }

    @objc
    func didTapAdd() {
        self.alertContainer.present { [weak self] action in
            guard case let .saved(text: tag) = action else { return }
            self?.presenter.addTag(tag)
        }
    }

    @objc
    func didTapSave() {
        let nullableTags = self.collectionView.indexPathsForSelectedItems?
            .compactMap { self.dataSource.itemIdentifier(for: $0) }
        guard let tags = nullableTags else { return }
        self.presenter.select(tags)
    }
}

extension TagSelectionViewController: TagSelectionViewProtocol {
    // MARK: - TagSelectionViewProtocol

    func apply(_ tags: [Tag]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
        snapshot.appendSections([.main])
        snapshot.appendItems(tags)
        self.dataSource.apply(snapshot)
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

extension TagSelectionViewController: TagCollectionViewDataSource {
    // MARK: - TagCollectionViewDataSource

    func displayMode(_ collectionView: UICollectionView) -> TagCollectionViewCell.DisplayMode {
        return .checkAtSelect
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
        // NOP
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // NOP
    }
}
