//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxCore
import TBoxUIKit
import UIKit

protocol ClipMergeViewControllerDelegate: AnyObject {
    func didComplete(_ viewController: ClipMergeViewController)
}

class ClipMergeViewController: UIViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipMergeViewModelType

    enum Section: Int {
        case tag
        case clip
    }

    enum Item: Hashable {
        case tagAddition
        case tag(Tag)
        case item(ClipItem)

        var identifier: String {
            switch self {
            case .tagAddition:
                return "tag-addition"

            case let .tag(tag):
                return tag.id.uuidString

            case let .item(clipItem):
                return clipItem.id.uuidString
            }
        }
    }

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: View

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    // MARK: Thumbnail

    private let thumbnailLoader: Domain.ThumbnailLoader

    // MARK: States

    private var cancellableBag = Set<AnyCancellable>()
    weak var delegate: ClipMergeViewControllerDelegate?

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: Dependency,
         thumbnailLoader: Domain.ThumbnailLoader)
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
                self?.apply(tags: tags, items: items)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.close
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true)
                self.delegate?.didComplete(self)
            }
            .store(in: &self.cancellableBag)
    }

    private func apply(tags: [Tag], items: [ClipItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Item.tagAddition] + tags.map({ Item.tag($0) }))
        snapshot.appendSections([.clip])
        snapshot.appendItems(items.map({ Item.item($0) }))
        self.dataSource.apply(snapshot)
    }

    private func items(tags: [Tag], items: [ClipItem]) -> [Item] {
        return [Item.tagAddition]
            + tags.map({ Item.tag($0) })
            + items.map({ Item.item($0) })
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
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: Self.createLayout())
        self.collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.collectionView.backgroundColor = Asset.Color.backgroundClient.color
        self.collectionView.contentInsetAdjustmentBehavior = .always

        self.collectionView.register(TagCollectionViewCell.nib, forCellWithReuseIdentifier: "tag")
        self.collectionView.register(TagCollectionAdditionCell.nib, forCellWithReuseIdentifier: "tag-addition")
        self.collectionView.register(ClipMergeImageCell.nib, forCellWithReuseIdentifier: "clip-selection")

        self.view.addSubview(collectionView)

        self.dataSource = .init(collectionView: self.collectionView, cellProvider: self.cellProvider())

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
            let items = self.items(tags: self.viewModel.outputs.tags.value,
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

    // MARK: CollectionView Layout

    private static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .clip:
                return GridLayout.makeSection(for: environment)

            case .none:
                return nil
            }
        }
        return layout
    }

    private static func createTagsLayoutSection() -> NSCollectionLayoutSection {
        let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: nil, bottom: .fixed(4))
        let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing)
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 4, trailing: 12)
        return section
    }

    // MARK: CollectionView DataSource

    private func cellProvider() -> (UICollectionView, IndexPath, Item) -> UICollectionViewCell? {
        return { [weak self] collectionView, indexPath, item -> UICollectionViewCell? in
            guard let self = self else { return nil }
            switch item {
            case .tagAddition:
                let configuration = TagCollectionView.CellConfiguration.Addition(title: "追加する",
                                                                                 delegate: self)
                return TagCollectionView.provideCell(collectionView: collectionView,
                                                     indexPath: indexPath,
                                                     configuration: .addition(configuration))

            case let .tag(tag):
                let configuration = TagCollectionView.CellConfiguration.Tag(tag: tag,
                                                                            displayMode: .normal,
                                                                            visibleDeleteButton: true,
                                                                            visibleCountIfPossible: false,
                                                                            delegate: self)
                return TagCollectionView.provideCell(collectionView: collectionView,
                                                     indexPath: indexPath,
                                                     configuration: .tag(configuration))

            case let .item(clipItem):
                let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: "clip-selection", for: indexPath)
                guard let cell = dequeuedCell as? ClipMergeImageCell else { return dequeuedCell }
                cell.identifier = clipItem.id

                let request = ThumbnailRequest(identifier: clipItem.id,
                                               cacheKey: "clip-merge-\(clipItem.id.uuidString)",
                                               originalDataLoadRequest: NewImageDataLoadRequest(imageId: clipItem.imageId),
                                               size: cell.thumbnailDisplaySize,
                                               scale: cell.traitCollection.displayScale)
                self.thumbnailLoader.load(request: request, observer: cell)

                return cell
            }
        }
    }
}

extension ClipMergeViewController: TagCollectionAdditionCellDelegate {
    // MARK: - TagCollectionAdditionCellDelegate

    func didTap(_ cell: TagCollectionAdditionCell) {
        let tags = self.viewModel.outputs.tags.value.map { $0.identity }
        guard let viewController = self.factory.makeTagSelectionViewController(selectedTags: tags, context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }
}

extension ClipMergeViewController: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let item = self.dataSource.itemIdentifier(for: indexPath),
            case let .tag(tag) = item else { return }
        self.viewModel.inputs.deleted.send(tag.id)
    }
}

extension ClipMergeViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?) {
        // NOP
    }

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, tags: [Tag]) {
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
            let section = Section(rawValue: sectionValue),
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
