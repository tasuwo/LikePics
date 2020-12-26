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
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipCreationViewModelType

    private lazy var itemDone = UIBarButtonItem(barButtonSystemItem: .save,
                                                target: self,
                                                action: #selector(saveAction))
    private lazy var itemReload = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(reloadAction))
    private let emptyMessageView = EmptyMessageView()
    @IBOutlet var collectionView: ClipSelectionCollectionView!
    @IBOutlet var selectedTagListContainer: UIView!
    @IBOutlet var selectedTagListContainerHeight: NSLayoutConstraint!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var baseScrollView: UIScrollView!

    private let factory: Factory
    private let viewModel: ClipCreationViewModelType
    private let thumbnailLoader: ThumbnailLoaderProtocol = ThumbnailLoader()

    private let selectedTagViewController: ClipCreationSelectedTagsViewController

    private var cancellableBag = Set<AnyCancellable>()
    private weak var delegate: ClipCreationDelegate?

    // MARK: - Lifecycle

    public init(factory: ViewControllerFactory,
                viewModel: ClipCreationViewModelType,
                tagsViewModel: ClipCreationSelectedTagsViewModelType,
                delegate: ClipCreationDelegate)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.delegate = delegate
        self.selectedTagViewController = ClipCreationSelectedTagsViewController(factory: factory,
                                                                                viewModel: tagsViewModel)
        super.init(nibName: "ClipCreationViewController", bundle: Bundle(for: Self.self))

        self.addChild(self.selectedTagViewController)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    // MARK: Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        self.selectedTagViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.selectedTagListContainer.addSubview(self.selectedTagViewController.view)
        NSLayoutConstraint.activate(self.selectedTagListContainer.constraints(fittingIn: self.selectedTagViewController.view))

        if let layout = self.collectionView?.collectionViewLayout as? ClipCollectionLayout {
            layout.delegate = self
        }

        self.setupAppearance()
        self.setupCollectionView()
        self.setupNavigationBar()
        self.setupEmptyMessage()

        self.bind(to: viewModel)

        self.viewModel.inputs.viewLoaded.send(self.view)
        self.viewModel.inputs.startedFindingImage.send(())
    }

    private func setupAppearance() {
        self.indicator.hidesWhenStopped = true
        self.view.backgroundColor = Asset.Color.background.color
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.isLoading
            .sink { [weak self] isLoading in
                isLoading
                    ? self?.indicator.startAnimating()
                    : self?.indicator.stopAnimating()
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.isReloadItemEnabled
            .assign(to: \.isEnabled, on: self.itemReload)
            .store(in: &self.cancellableBag)

        dependency.outputs.isDoneItemEnabled
            .assign(to: \.isEnabled, on: self.itemDone)
            .store(in: &self.cancellableBag)

        // TODO: 将来的にScrollViewをCollectionViewに置き換える
        dependency.outputs.displayCollectionView
            .map { !$0 }
            .assign(to: \.isHidden, on: self.baseScrollView)
            .store(in: &self.cancellableBag)

        dependency.outputs.displayEmptyMessage
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.cancellableBag)

        dependency.outputs.images
            .sink { [weak self] _ in self?.collectionView.reloadData() }
            .store(in: &self.cancellableBag)

        dependency.outputs.selectedIndices
            .sink { [weak self] indices in
                guard let self = self else { return }

                indices.enumerated().forEach { idx, index in
                    guard let cell = self.collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? ClipSelectionCollectionViewCell else { return }
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
                alert.addAction(.init(title: L10n.clipCreationViewOverwriteAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.didFinish
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.didFinish(self)
            }
            .store(in: &self.cancellableBag)

        self.selectedTagViewController.viewModel.outputs.tags
            .sink { [weak self] tags in
                self?.viewModel.inputs.selectedTags.send(tags)
            }
            .store(in: &self.cancellableBag)

        self.selectedTagViewController.contentViewHeight
            // HACK: CollectionView更新後即座に `layoutIfNeeded` を呼び出すとクラッシュするため、その回避
            .debounce(for: 0.1, scheduler: RunLoop.main)
            .sink { [weak self] height in
                self?.selectedTagListContainerHeight.constant = height
                UIView.animate(withDuration: 0.2) { [weak self] in
                    self?.view.layoutIfNeeded()
                }
            }
            .store(in: &self.cancellableBag)
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        self.collectionView.backgroundColor = Asset.Color.background.color
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
        self.viewModel.inputs.startedFindingImage.send(())
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

extension ClipCreationViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return self.viewModel.outputs.images.value.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return self.viewModel.outputs.images.value.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return self.viewModel.outputs.images.value.indices.contains(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.viewModel.inputs.select.send(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.viewModel.inputs.deselect.send(indexPath.row)
    }
}

extension ClipCreationViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.outputs.images.value.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: type(of: self.collectionView).cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipSelectionCollectionViewCell else { return dequeuedCell }
        guard self.viewModel.outputs.images.value.indices.contains(indexPath.row) else { return cell }

        let source = self.viewModel.outputs.images.value[indexPath.row]
        cell.id = source.identifier

        self.thumbnailLoader.load(from: source)
            .receive(on: DispatchQueue.main)
            .sink { image in
                guard cell.id == source.identifier else { return }
                cell.image = image
            }
            .store(in: &self.cancellableBag)

        if let indexInSelection = self.viewModel.outputs.selectedIndices.value.firstIndex(of: indexPath.row) {
            cell.selectionOrder = indexInSelection + 1
        }

        return cell
    }
}

extension ClipCreationViewController: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    public func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard self.viewModel.outputs.images.value.indices.contains(indexPath.row),
            let size = self.viewModel.outputs.images.value[indexPath.row].resolveSize()
        else {
            return .zero
        }
        return width * CGFloat(size.height / size.width)
    }

    public func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return .zero
    }
}

extension ClipCreationViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        self.viewModel.inputs.startedFindingImage.send(())
    }
}