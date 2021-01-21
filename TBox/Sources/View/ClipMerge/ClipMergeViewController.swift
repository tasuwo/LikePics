//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxCore
import TBoxUIKit
import UIKit

protocol ClipMergeViewControllerDelegate: AnyObject {
    func didComplete(_ viewController: ClipMergeViewController)
}

class ClipMergeViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipMergeViewModelType
    typealias Layout = ClipMergeViewLayout

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: ClipMergeViewLayout.DataSource!
    private var proxy: Layout.Proxy!
    private lazy var interactionHandler: URLButtonInteractionHandler = {
        let handler = URLButtonInteractionHandler()
        handler.baseView = view
        return handler
    }()

    // MARK: Thumbnail

    private let thumbnailLoader: ThumbnailLoader

    // MARK: States

    private var subscriptions = Set<AnyCancellable>()
    weak var delegate: ClipMergeViewControllerDelegate?

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

        self.setupAppearance()
        self.setupNavigationBar()
        self.setupCollectionView()

        self.bind(to: viewModel)
    }

    // MARK: - Methods

    // MARK: Appearance

    private func setupAppearance() {
        self.view.backgroundColor = Asset.Color.backgroundClient.color
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.items
            .receive(on: DispatchQueue.main)
            .combineLatest(dependency.outputs.tags)
            .sink { [weak self] items, tags in
                self?.dataSource.apply(ClipMergeViewLayout.createSnapshot(tags: tags, items: items))
            }
            .store(in: &self.subscriptions)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.close
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true)
                self.delegate?.didComplete(self)
            }
            .store(in: &self.subscriptions)
    }

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.clipMergeViewTitle
        self.navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(self.didTapCancel))
        self.navigationItem.rightBarButtonItem = .init(barButtonSystemItem: .save, target: self, action: #selector(self.didTapSave))
    }

    @objc
    func didTapSave() {
        self.viewModel.inputs.saved.send(())
    }

    @objc
    func didTapCancel() {
        self.dismiss(animated: true)
        self.delegate?.didComplete(self)
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        self.collectionView = UICollectionView(frame: self.view.bounds,
                                               collectionViewLayout: ClipMergeViewLayout.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color

        self.view.addSubview(collectionView)

        // DataSource

        let (dataSource, proxy) = ClipMergeViewLayout.createDataSource(collectionView: self.collectionView,
                                                                       thumbnailLoader: self.thumbnailLoader)
        self.dataSource = dataSource
        self.proxy = proxy
        self.proxy.delegate = self
        self.proxy.interactionDelegate = interactionHandler

        // Reorder settings

        self.collectionView.dragInteractionEnabled = true

        self.dataSource.reorderingHandlers.canReorderItem = { item in
            switch item {
            case .item:
                return true

            default:
                return false
            }
        }

        self.dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            let items = ClipMergeViewLayout.createItems(tags: self.viewModel.outputs.tags.value,
                                                        items: self.viewModel.outputs.items.value)
                .applying(transaction.difference)?
                .compactMap { item -> ClipItem? in
                    switch item {
                    case let .item(clipItem):
                        return clipItem

                    default:
                        return nil
                    }
                }
            if let items = items {
                self.viewModel.inputs.reordered.send(items)
            }
        }

        self.collectionView.dragDelegate = self
        self.collectionView.dropDelegate = self
    }
}

extension ClipMergeViewController: ClipMergeViewDelegate {
    // MARK: - ClipMergeViewDelegate

    func didTapTagAdditionButton(_ cell: UICollectionViewCell) {
        let tags = self.viewModel.outputs.tags.value.map { $0.identity }
        guard let viewController = self.factory.makeTagSelectionViewController(selectedTags: tags, context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let item = self.dataSource.itemIdentifier(for: indexPath),
            case let .tag(tag) = item else { return }
        self.viewModel.inputs.deleted.send(tag.id)
    }

    func didTapSiteUrl(_ sender: UIView, url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

extension ClipMergeViewController: TagSelectionDelegate {
    // MARK: - TagSelectionDelegate

    func tagSelection(_ sender: AnyObject, didSelectTags tags: [Tag], withContext context: Any?) {
        self.viewModel.inputs.tagsSelected.send(tags)
    }
}

extension ClipMergeViewController: UICollectionViewDragDelegate {
    // MARK: - UICollectionViewDragDelegate

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = self.dataSource.itemIdentifier(for: indexPath) else { return [] }
        let provider = NSItemProvider(object: item.identifier as NSString)
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

extension ClipMergeViewController: UICollectionViewDropDelegate {
    // MARK: - UICollectionViewDropDelegate

    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let sectionValue = destinationIndexPath?.section,
            let section = ClipMergeViewLayout.Section(rawValue: sectionValue),
            section == .clip
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
