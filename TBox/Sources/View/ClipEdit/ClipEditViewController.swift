//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

class ClipEditViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipEditViewModelType
    typealias Layout = ClipEditViewLayout

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var proxy: Layout.Proxy!
    private lazy var editSiteUrlAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.clipPreviewViewAlertForEditSiteUrlTitle,
                             message: L10n.clipPreviewViewAlertForEditSiteUrlMessage,
                             placeholder: L10n.clipPreviewViewAlertForEditSiteUrlPlaceholder)
    )
    private lazy var interactionHandler: URLButtonInteractionHandler = {
        let handler = URLButtonInteractionHandler()
        handler.baseView = view
        return handler
    }()

    // MARK: Thumbnail

    private let thumbnailLoader: ThumbnailLoader

    // MARK: States

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: Dependency,
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

        configureCollectionView()
        configureNavigationBar()

        bind(to: viewModel)
    }

    // MARK: - Methods

    private func configureCollectionView() {
        self.collectionView = UICollectionView(frame: self.view.bounds,
                                               collectionViewLayout: Layout.createLayout(delegate: self))
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color

        self.view.addSubview(collectionView)

        let (dataSource, proxy) = Layout.createDataSource(collectionView: collectionView, thumbnailLoader: thumbnailLoader)
        self.dataSource = dataSource
        self.proxy = proxy
        self.proxy.delegate = self
        self.proxy.interactionDelegate = interactionHandler
        self.collectionView.delegate = self

        self.collectionView.dragInteractionEnabled = true
        self.dataSource.reorderingHandlers.canReorderItem = { $0.canReorder }
        self.dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            self?.viewModel.inputs.reordered(transaction.finalSnapshot)
        }

        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
    }

    private func configureNavigationBar() {
        self.title = L10n.clipEditViewTitle
        self.navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .done, target: self, action: #selector(didTapDone(_:)))
    }

    @objc
    private func didTapDone(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ClipEditViewController {
    // MARK: - Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.applySnapshot
            .receive(on: DispatchQueue.main)
            .sink { [weak self] snapshot in self?.dataSource.apply(snapshot) }
            .store(in: &subscriptions)

        dependency.outputs.applyDeletions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items, completion in
                guard let self = self else { return }
                var snapshot = self.dataSource.snapshot()
                snapshot.deleteItems(items)
                self.dataSource.apply(snapshot, animatingDifferences: true, completion: completion)
            }
            .store(in: &subscriptions)

        dependency.outputs.close
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.dismiss(animated: true, completion: nil) }
            .store(in: &subscriptions)
    }
}

extension ClipEditViewController {
    // MARK: - Alert

    func presentDeleteAlert(at cell: UICollectionViewCell, deleteClipAction: @escaping () -> Void) {
        let alert = UIAlertController(title: nil,
                                      message: L10n.clipEditViewAlertForDeleteClipMessage,
                                      preferredStyle: .actionSheet)

        alert.addAction(.init(title: L10n.clipEditViewAlertForDeleteClipTitle,
                              style: .destructive,
                              handler: { _ in deleteClipAction() }))

        alert.addAction(.init(title: L10n.confirmAlertCancel, style: .cancel, handler: nil))

        alert.popoverPresentationController?.sourceView = collectionView
        alert.popoverPresentationController?.sourceRect = cell.frame

        self.present(alert, animated: true, completion: nil)
    }
}

extension ClipEditViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath),
            case .deleteClip = item else { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
            let cell = collectionView.cellForItem(at: indexPath),
            case .deleteClip = item else { return }
        self.presentDeleteAlert(at: cell) { [weak self] in
            self?.viewModel.inputs.deleteClip()
        }
    }
}

extension ClipEditViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath), case let .clipItem(clipItem) = item else { return [] }
        let provider = NSItemProvider(object: clipItem.itemId.uuidString as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = indexPath
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipEditViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let sectionValue = destinationIndexPath?.section,
            let section = ClipEditViewLayout.Section(rawValue: sectionValue),
            section == .clipItem
        else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        // NOP
    }

    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        return parameters
    }
}

extension ClipEditViewController: ClipEditViewDelegate {
    // MARK: - ClipEditViewDelegate

    func trailingSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard case .clipItem = Layout.Section(rawValue: indexPath.section),
            viewModel.outputs.isItemDeletable else { return nil }

        let deleteAction = UIContextualAction(style: .destructive,
                                              title: L10n.clipEditViewDeleteClipItemTitle) { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }
            self.viewModel.inputs.delete(itemAt: indexPath.row, completion: completion)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool) {
        guard case .meta = self.dataSource.itemIdentifier(for: indexPath) else { return }
        if isOn {
            viewModel.inputs.hideClip()
        } else {
            viewModel.inputs.revealClip()
        }
    }

    func didTapTagAdditionButton(_ cell: UICollectionViewCell) {
        let tagIds = viewModel.outputs.tags.map { $0.id }
        let nullableViewController = self.factory.makeTagSelectionViewController(selectedTags: tagIds, context: nil, delegate: self)
        guard let viewController = nullableViewController else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .tag(tag) = item else { return }
        viewModel.inputs.removeTagFromClip(tag.id)
    }

    func didTapSiteUrl(_ sender: UIView, url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func didTapSiteUrlEditButton(_ sender: UIView, url: URL?) {
        guard let cell = sender.next(ofType: UICollectionViewCell.self),
            let indexPath = collectionView.indexPath(for: cell),
            let item = dataSource.itemIdentifier(for: indexPath),
            case let .clipItem(clipItem) = item else { return }
        self.editSiteUrlAlertContainer.present(withText: url?.absoluteString, on: self) {
            guard let text = $0 else { return true }
            return text.isEmpty || URL(string: text) != nil
        } completion: { [weak self] action in
            guard case let .saved(text: text) = action else { return }
            self?.viewModel.inputs.update(siteUrl: URL(string: text), forItem: clipItem.itemId)
        }
    }
}

extension ClipEditViewController: TagSelectionDelegate {
    // MARK: - TagSelectionViewControllerDelegate

    func tagSelection(_ sender: AnyObject, didSelectTags tags: [Tag], withContext context: Any?) {
        let tagIds = Set(tags.map { $0.id })
        viewModel.inputs.replaceTagsOfClip(tagIds)
    }
}
