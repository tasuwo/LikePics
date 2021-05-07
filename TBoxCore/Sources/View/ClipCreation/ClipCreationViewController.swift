//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Smoothie
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
    typealias Layout = ClipCreationViewLayout

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: Dependency

    private let viewModel: Dependency

    // MARK: IBOutlets

    @IBOutlet var overlayView: UIView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MARK: Views

    private lazy var addUrlAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.clipCreationViewAlertForAddUrlTitle,
                             message: L10n.clipCreationViewAlertForAddUrlMessage,
                             placeholder: L10n.clipCreationViewAlertForUrlPlaceholder)
    )
    private lazy var editUrlAlertContainer = TextEditAlert(
        configuration: .init(title: L10n.clipCreationViewAlertForEditUrlTitle,
                             message: L10n.clipCreationViewAlertForEditUrlMessage,
                             placeholder: L10n.clipCreationViewAlertForUrlPlaceholder)
    )
    private lazy var itemDone = UIBarButtonItem(barButtonSystemItem: .save,
                                                target: self,
                                                action: #selector(saveAction))
    private lazy var itemReload = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(reloadAction))
    private let emptyMessageView = EmptyMessageView()
    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var proxy: Layout.Proxy!

    // MARK: Services

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: States

    private var subscriptions = Set<AnyCancellable>()
    private weak var delegate: ClipCreationDelegate?
    private let clipsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBoxCore.ClipCreationViewController", qos: .userInteractive)

    // MARK: - Lifecycle

    public init(factory: ViewControllerFactory,
                viewModel: ClipCreationViewModelType,
                thumbnailLoader: ThumbnailLoaderProtocol,
                delegate: ClipCreationDelegate)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.thumbnailLoader = thumbnailLoader
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
                    ? UIColor.black.withAlphaComponent(0.4)
                    : .clear
                if isLoading {
                    self?.indicator.startAnimating()
                    self?.overlayView.isHidden = false
                } else {
                    self?.indicator.stopAnimating()
                    self?.overlayView.isHidden = true
                }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.isReloadItemEnabled
            .assign(to: \.isEnabled, on: self.itemReload)
            .store(in: &self.subscriptions)

        dependency.outputs.isDoneItemEnabled
            .assign(to: \.isEnabled, on: self.itemDone)
            .store(in: &self.subscriptions)

        dependency.outputs.displayReloadButton
            .map { [weak self] display in display ? self?.itemReload : nil }
            .map { [$0].compactMap { $0 } }
            .assign(to: \.leftBarButtonItems, on: self.navigationItem)
            .store(in: &self.subscriptions)

        dependency.outputs.displayCollectionView
            .map { !$0 }
            .assign(to: \.isHidden, on: self.collectionView)
            .store(in: &self.subscriptions)

        dependency.outputs.displayEmptyMessage
            .map { $0 ? 1 : 0 }
            .assign(to: \.alpha, on: self.emptyMessageView)
            .store(in: &self.subscriptions)

        dependency.outputs.applySnapshot
            .receive(on: clipsUpdateQueue)
            .sink { [weak self] snapshot in
                self?.dataSource.apply(snapshot, animatingDifferences: true) {
                    guard let self = self else { return }
                    self.apply(indices: self.viewModel.outputs.selectedIndices.value)
                }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.selectedIndices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] indices in self?.apply(indices: indices) }
            .store(in: &self.subscriptions)

        dependency.outputs.emptyErrorTitle
            .assign(to: \.title, on: self.emptyMessageView)
            .store(in: &self.subscriptions)
        dependency.outputs.emptyErrorMessage
            .assign(to: \.message, on: self.emptyMessageView)
            .store(in: &self.subscriptions)

        dependency.outputs.displayAlert
            .sink { [weak self] title, message in
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.didFinish
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.delegate?.didFinish(self)
            }
            .store(in: &self.subscriptions)
    }

    private func apply(indices: [Int]) {
        let indexPaths = indices.map { IndexPath(row: $0, section: Layout.Section.image.rawValue) }
        let selectedIndexPaths = self.collectionView.indexPathsForSelectedItems ?? []

        // 足りない分を選択する
        Set(indexPaths).subtracting(selectedIndexPaths)
            .forEach { self.collectionView.selectItem(at: $0, animated: false, scrollPosition: []) }

        // 並び順を更新する
        indexPaths.enumerated().forEach { idx, indexPath in
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? ClipSelectionCollectionViewCell else { return }
            cell.selectionOrder = idx + 1
        }

        // 余剰な部分を選択解除する
        selectedIndexPaths
            .filter { !indices.contains($0.row) }
            .forEach { self.collectionView.deselectItem(at: $0, animated: false) }
    }

    // MARK: CollectionView

    private func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds,
                                          collectionViewLayout: Layout.createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = Asset.Color.background.color
        collectionView.contentInsetAdjustmentBehavior = .always
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.isHidden = true

        view.addSubview(collectionView)

        let (proxy, dataSource) = Layout.configureDataSource(collectionView: collectionView,
                                                             thumbnailLoader: self.thumbnailLoader,
                                                             outputs: viewModel.outputs)
        self.dataSource = dataSource
        proxy.delegate = self
        self.proxy = proxy
    }

    // MARK: NavigationBar

    private func setupNavigationBar() {
        self.navigationItem.title = L10n.clipCreationViewTitle

        [self.itemReload, self.itemDone].forEach {
            $0.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .disabled)
            $0.isEnabled = false
        }

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

extension ClipCreationViewController: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard case .image = Layout.Section(rawValue: indexPath.section) else { return false }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        guard case .image = Layout.Section(rawValue: indexPath.section) else { return false }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard case .image = Layout.Section(rawValue: indexPath.section) else { return false }
        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case .image = Layout.Section(rawValue: indexPath.section) else { return }
        self.viewModel.inputs.selectedImage.send(indexPath.row)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard case .image = Layout.Section(rawValue: indexPath.section) else { return }
        self.viewModel.inputs.deselectedImage.send(indexPath.row)
    }
}

extension ClipCreationViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        self.viewModel.inputs.loadImages.send(())
    }
}

extension ClipCreationViewController: TagSelectionViewControllerDelegate {
    // MARK: - TagSelectionViewControllerDelegate

    public func didSelectTags(tags: [Tag]) {
        self.viewModel.inputs.replacedTags.send(tags)
    }
}

extension ClipCreationViewController: ClipCreationViewDelegate {
    // MARK: - ClipCreationViewDelegate

    public func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool) {
        self.viewModel.inputs.hidingUpdated.send(isOn)
    }

    public func didTapButton(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
        self.startUrlEditing()
    }

    private func startUrlEditing() {
        if let url = viewModel.outputs.url {
            self.editUrlAlertContainer.present(
                withText: url.absoluteString,
                on: self,
                validator: { text in
                    guard let text = text else { return true }
                    return text.isEmpty || URL(string: text) != nil
                }, completion: { [weak self] action in
                    guard case let .saved(text: text) = action else { return }
                    self?.viewModel.inputs.urlEdited.send(URL(string: text))
                }
            )
        } else {
            self.addUrlAlertContainer.present(
                withText: nil,
                on: self,
                validator: { text in
                    guard let text = text else { return true }
                    return text.isEmpty || URL(string: text) != nil
                }, completion: { [weak self] action in
                    guard case let .saved(text: text) = action else { return }
                    self?.viewModel.inputs.urlEdited.send(URL(string: text))
                }
            )
        }
    }

    public func didTapTagAdditionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let section = Layout.Section(rawValue: indexPath.section) else { return }
        switch section {
        case .tag:
            self.presentTagSelectionView()

        default:
            return
        }
    }

    public func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
              let item = self.dataSource.itemIdentifier(for: indexPath),
              case let .tag(tag) = item
        else {
            return
        }
        self.viewModel.inputs.deletedTag.send(tag)
    }

    private func presentTagSelectionView() {
        guard let parent = self.parent else {
            return
        }
        let selectedTags = Set(self.viewModel.outputs.tags.value.map({ $0.identity }))
        guard let nextVC = self.factory.makeTagSelectionViewController(selectedTags: selectedTags, delegate: self) else {
            return
        }
        parent.present(nextVC, animated: true, completion: nil)
    }
}
