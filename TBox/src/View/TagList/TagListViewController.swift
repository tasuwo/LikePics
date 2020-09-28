//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxUIKit
import UIKit

class TagListViewController: UIViewController {
    typealias Factory = ViewControllerFactory

    enum Section {
        case main
    }

    private let factory: Factory
    private let presenter: TagListPresenter
    private let logger: TBoxLoggable
    private lazy var alertContainer = AddingAlert(configuration: .init(title: L10n.tagListViewAlertForAddTitle,
                                                                       message: L10n.tagListViewAlertForAddMessage,
                                                                       placeholder: L10n.tagListViewAlertForAddPlaceholder),
                                                  baseView: self)
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var dataSource: UICollectionViewDiffableDataSource<Section, Tag>!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var collectionView: TagCollectionView!

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

        self.setupCollecitonView()
        self.setupAppearance()
        self.updateNavigationBar(for: self.isEditing)

        self.presenter.setup()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.title = L10n.tagListViewTitle
    }

    // MARK: Collection View

    private func setupCollecitonView() {
        self.collectionView = TagCollectionView(frame: self.view.bounds, collectionViewLayout: TagCollectionLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.backgroundClient.color
        self.view.addSubview(self.collectionView)
        self.collectionView.delegate = self
        self.collectionView.allowsSelection = true
        self.collectionView.allowsMultipleSelection = false
        self.configureDataSouce()
    }

    private func configureDataSouce() {
        self.dataSource = .init(collectionView: self.collectionView) { [weak self] collectionView, indexPath, tag -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
            guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }

            cell.title = tag.name
            cell.displayMode = self?.isEditing == true ? .deletion : .normal

            return cell
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
        self.alertContainer.present { [weak self] action in
            guard case let .saved(text: tag) = action else { return }
            self?.presenter.addTag(tag)
        }
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
            self.presenter.delete(indices.compactMap({ self.dataSource.itemIdentifier(for: $0) }))
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

    func apply(_ tags: [Tag]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Tag>()
        snapshot.appendSections([.main])
        snapshot.appendItems(tags)
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

extension TagListViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let tag = self.dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        if !self.isEditing {
            self.presenter.select(tag)
        }
    }
}

extension TagListViewController: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let tag = self.dataSource.itemIdentifier(for: indexPath) else { return .zero }
        let preferredSize = TagCollectionViewCell.preferredSize(for: tag.name)
        return CGSize(width: fmin(preferredSize.width, collectionView.frame.width - 16 * 2), height: preferredSize.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 16, bottom: 16, right: 16)
    }
}
