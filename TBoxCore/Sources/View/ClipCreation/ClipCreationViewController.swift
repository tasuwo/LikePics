//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxUIKit
import UIKit

public protocol ClipCreationDelegate: AnyObject {
    func didCancel(_ viewController: ClipCreationViewController)
    func didFinish(_ viewController: ClipCreationViewController)
}

protocol SelectableImageCellDataSource {
    var url: URL { get }
    var height: CGFloat { get }
    var width: CGFloat { get }
}

public class ClipCreationViewController: UIViewController {
    // MARK: - Type Aliases

    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipCreationViewModelType

    // MARK: - Enums

    enum Section: Int {
        case tag
        case image
    }

    enum Item: Hashable {
        case tagAddition
        case tag(Tag)
        case image(ImageSource)

        var identifier: String {
            switch self {
            case .tagAddition:
                return "tag-addition"

            case let .tag(tag):
                return tag.id.uuidString

            case let .image(source):
                return source.identifier.uuidString
            }
        }
    }

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: IBOutlets

    @IBOutlet var overlayView: UIView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: Views

    private lazy var itemDone = UIBarButtonItem(barButtonSystemItem: .save,
                                                target: self,
                                                action: #selector(saveAction))
    private lazy var itemReload = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(reloadAction))
    private let emptyMessageView = EmptyMessageView()
    private var collectionView: UICollectionView!

    // MARK: Services

    private let thumbnailLoader: ThumbnailLoaderProtocol = ThumbnailLoader()

    // MARK: States

    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    private var cancellableBag = Set<AnyCancellable>()
    private let downsamplingQueue = DispatchQueue(label: "net.tasuwo.TBox.TBoxCore.ClipCreationViewController.downsampling")
    private weak var delegate: ClipCreationDelegate?

    // MARK: - Lifecycle

    public init(factory: ViewControllerFactory,
                viewModel: ClipCreationViewModelType,
                delegate: ClipCreationDelegate)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: "ClipCreationViewController", bundle: Bundle(for: Self.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.setupAppearance()
        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupEmptyMessage()

        view.bringSubviewToFront(overlayView)

        self.bind(to: viewModel)

        self.viewModel.inputs.viewLoaded.send(self.view)
        self.viewModel.inputs.loadImages.send(())
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.viewModel.inputs.viewDidAppear.send(())
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.view.backgroundColor = Asset.Color.background.color
        self.navigationItem.hidesBackButton = true
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.isLoading
            .combineLatest(dependency.outputs.displayCollectionView)
            .sink { [weak self] isLoading, displayCollectionView in
                self?.overlayView.backgroundColor = displayCollectionView
                    ? UIColor.black.withAlphaComponent(0.8)
                    : .clear
                if isLoading {
                    self?.indicator.startAnimating()
                    self?.overlayView.isHidden = false
                } else {
                    self?.indicator.stopAnimating()
                    self?.overlayView.isHidden = true
                }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.isReloadItemEnabled
            .assign(to: \.isEnabled, on: self.itemReload)
            .store(in: &self.cancellableBag)

        dependency.outputs.isDoneItemEnabled
            .assign(to: \.isEnabled, on: self.itemDone)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayCollectionView
            .map { !$0 }
            .assign(to: \.isHidden, on: self.collectionView)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayEmptyMessage
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.tags
            .combineLatest(dependency.outputs.images)
            .receive(on: DispatchQueue.global())
            .sink { [weak self] tags, images in self?.apply(tags: tags, images: images) }
            .store(in: &self.cancellableBag)

        dependency.outputs.selectedIndices
            .sink { [weak self] indices in
                guard let self = self else { return }

                indices.enumerated().forEach { idx, index in
                    guard let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: Section.image.rawValue)) as? ClipSelectionCollectionViewCell else { return }
                    cell.selectionOrder = idx + 1
                }

                self.collectionView.indexPathsForSelectedItems?
                    .filter { !indices.contains($0.row) }
                    .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.emptyErrorTitle
            .assign(to: \.title, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)
        dependency.outputs.emptyErrorMessage
            .assign(to: \.message, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayAlert
            .sink { [weak self] title, message in
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.didFinish
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.didFinish(self)
            }
            .store(in: &self.cancellableBag)
    }

    private func apply(tags: [Tag], images: [ImageSource]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Item.tagAddition] + tags.map({ Item.tag($0) }))
        snapshot.appendSections([.image])
        snapshot.appendItems(images.map({ Item.image($0) }))
        self.dataSource.apply(snapshot)
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Self.createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = Asset.Color.background.color
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.isHidden = true

        view.addSubview(collectionView)

        configureDataSource()
    }

    private func configureDataSource() {
        let additionCellRegistration = UICollectionView.CellRegistration<TagCollectionAdditionCell, Void>(cellNib: TagCollectionAdditionCell.nib) { [weak self] cell, _, _ in
            cell.title = L10n.clipCreationViewAdditionTitle
            cell.delegate = self
        }

        let tagCellRegistration = UICollectionView.CellRegistration<TagCollectionViewCell, Tag>(cellNib: TagCollectionViewCell.nib) { [weak self] cell, _, tag in
            cell.title = tag.name
            cell.displayMode = .normal
            cell.visibleCountIfPossible = false
            cell.visibleDeleteButton = true
            cell.delegate = self
        }

        let imageCellRegistration = UICollectionView.CellRegistration<ClipSelectionCollectionViewCell, ImageSource>(cellNib: ClipSelectionCollectionViewCell.nib) { [weak self] cell, indexPath, source in
            guard let self = self else { return }

            cell.id = source.identifier

            let imageViewSize = cell.imageDisplaySize
            let scale = cell.traitCollection.displayScale
            self.downsamplingQueue.async {
                self.thumbnailLoader.load(source, as: imageViewSize, scale: scale)
                    .filter { _ in cell.id == source.identifier }
                    .receive(on: DispatchQueue.main)
                    .assign(to: \.image, on: cell)
                    .store(in: &self.cancellableBag)
            }

            if let indexInSelection = self.viewModel.outputs.selectedIndices.value.firstIndex(of: indexPath.row) {
                cell.selectionOrder = indexInSelection + 1
            }
        }

        self.dataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: additionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .image(source):
                return collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: source)
            }
        }
    }

    private static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .image:
                return self.createImageLayoutSection(for: environment)

            case .none:
                return nil
            }
        }
        return layout
    }

    private static func createTagsLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(36),
                                              heightDimension: .estimated(32))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(32))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(16)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        return section
    }

    private static func createImageLayoutSection(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let count: Int = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return 2

            case .regular, .unspecified:
                return 3

            @unknown default:
                return 3
            }
        }()
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1 / CGFloat(count)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(16)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)

        return section
    }

    private static func predictCellSize(for collectionView: UICollectionView) -> CGSize {
        let numberOfColumns: CGFloat = {
            switch collectionView.traitCollection.horizontalSizeClass {
            case .compact:
                return 2

            case .regular, .unspecified:
                return 3

            @unknown default:
                return 3
            }
        }()
        let totalSpaceSize: CGFloat = 16 * 2 + (numberOfColumns - 1) * 16
        let width = (collectionView.bounds.size.width - totalSpaceSize) / numberOfColumns
        return CGSize(width: width, height: width)
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.clipCreationViewTitle

        [self.itemReload, self.itemDone].forEach {
            $0.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .disabled)
            $0.isEnabled = false
        }

        self.navigationItem.setLeftBarButton(self.itemReload, animated: true)
        self.navigationItem.setRightBarButton(self.itemDone, animated: true)
    }

    @objc
    private func saveAction() {
        self.viewModel.inputs.saveImages.send(())
    }

    @objc
    private func reloadAction() {
        self.viewModel.inputs.loadImages.send(())
    }

    // MARK: EmptyMessage

    private func setupEmptyMessage() {
        self.view.addSubview(self.emptyMessageView)

        self.emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(self.emptyMessageView.constraints(fittingIn: self.view.safeAreaLayoutGuide))

        self.emptyMessageView.title = nil
        self.emptyMessageView.message = nil
        self.emptyMessageView.actionButtonTitle = L10n.clipCreationViewLoadingErrorAction
        self.emptyMessageView.delegate = self

        self.emptyMessageView.alpha = 0
    }
}

extension ClipCreationViewController: UICollectionViewDataSourcePrefetching {
    // MARK: - UICollectionViewDataSourcePrefetching

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let imageViewSize = Self.predictCellSize(for: collectionView)
            let scale = self.collectionView.traitCollection.displayScale
            self.downsamplingQueue.async {
                guard case let .image(source) = self.dataSource.itemIdentifier(for: indexPath) else { return }
                self.thumbnailLoader.load(source, as: imageViewSize, scale: scale)
                    .sink { _ in }
                    .store(in: &self.cancellableBag)
            }
        }
    }
}

extension ClipCreationViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard case .image = Section(rawValue: indexPath.section) else { return false }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard case .image = Section(rawValue: indexPath.section) else { return false }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard case .image = Section(rawValue: indexPath.section) else { return false }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .image = Section(rawValue: indexPath.section) else { return }
        self.viewModel.inputs.selectedImage.send(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard case .image = Section(rawValue: indexPath.section) else { return }
        self.viewModel.inputs.deselectedImage.send(indexPath.row)
    }
}

extension ClipCreationViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        self.viewModel.inputs.loadImages.send(())
    }
}

extension ClipCreationViewController: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    public func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
            let item = self.dataSource.itemIdentifier(for: indexPath),
            case let .tag(tag) = item
        else {
            return
        }
        self.viewModel.inputs.deletedTag.send(tag)
    }
}

extension ClipCreationViewController: TagCollectionAdditionCellDelegate {
    // MARK: - TagCollectionAdditionCellDelegate

    public func didTap(_ cell: TagCollectionAdditionCell) {
        guard let parent = self.parent else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: "Failed to resolve parent view controller for opening tag selection view"))
            return
        }
        let selectedTags = Set(self.viewModel.outputs.tags.value.map({ $0.identity }))
        guard let nextVC = self.factory.makeTagSelectionViewController(selectedTags: selectedTags, delegate: self) else {
            RootLogger.shared.write(ConsoleLog(level: .error, message: "Failed to open tag selection view"))
            return
        }
        parent.present(nextVC, animated: true, completion: nil)
    }
}

extension ClipCreationViewController: TagSelectionViewControllerDelegate {
    // MARK: - TagSelectionViewControllerDelegate

    public func didSelectTags(tags: [Tag]) {
        self.viewModel.inputs.replacedTags.send(tags)
    }
}
