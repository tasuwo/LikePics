//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import ForestKit
import LikePicsUIKit
import Smoothie
import UIKit

public protocol ClipCreationDelegate: AnyObject {
    func didCancel(_ viewController: ClipCreationViewController)
    func didFinish(_ viewController: ClipCreationViewController)
}

public class ClipCreationViewController: UIViewController {
    // MARK: - Type Aliases

    typealias Factory = ViewControllerFactory
    typealias Layout = ClipCreationViewLayout
    typealias Store = ForestKit.Store<ClipCreationViewState, ClipCreationViewAction, ClipCreationViewDependency>

    // MARK: - Properties

    // MARK: Factory

    private let factory: Factory

    // MARK: View

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
    private let overlayView = UIView()
    private let indicator = UIActivityIndicatorView()
    private var collectionView: UICollectionView!
    private var dataSource: Layout.DataSource!
    private var proxy: Layout.Proxy!

    // MARK: Services

    private let thumbnailLoader: ThumbnailLoaderProtocol

    // MARK: Store/Subscription

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private let clipsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBoxCore.ClipCreationViewController", qos: .userInteractive)
    private weak var delegate: ClipCreationDelegate?

    // MARK: - Initializers

    public init(factory: ViewControllerFactory,
                state: ClipCreationViewState,
                dependency: ClipCreationViewDependency,
                thumbnailLoader: ThumbnailLoaderProtocol,
                delegate: ClipCreationDelegate)
    {
        self.factory = factory
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipCreationViewReducer())
        self.thumbnailLoader = thumbnailLoader
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureDataSource()

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    // MARK: - IBActions

    @objc
    private func saveAction() {
        store.execute(.saveImages)
    }

    @objc
    private func reloadAction() {
        store.execute(.viewDidLoad)
    }
}

extension ClipCreationViewController {
    private func bind(to store: Store) {
        store.state
            .throttle(for: 0.5, scheduler: RunLoop.main, latest: true)
            .receive(on: clipsUpdateQueue)
            .sink { [weak self] state in
                guard let self = self else { return }
                let snapshot = self.makeSnapshot(state)
                self.dataSource.apply(snapshot)
                DispatchQueue.main.async {
                    self.applySelection(state)
                }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.shouldSaveAsClip) { [weak self] shouldSaveAsClip in
                self?.collectionView.visibleCells
                    .compactMap { $0 as? ClipSelectionCollectionViewCell }
                    .forEach { $0.displaySelectionOrder = shouldSaveAsClip }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isLoading) { [weak self] isLoading in
                if isLoading {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isOverlayHidden, to: \.isHidden, on: overlayView)
            .store(in: &subscriptions)

        store.state
            .bind(\.isReloadItemEnabled, to: \.isEnabled, on: itemReload)
            .store(in: &subscriptions)

        store.state
            .bind(\.isDoneItemEnabled, to: \.isEnabled, on: itemDone)
            .store(in: &subscriptions)

        store.state
            .bind(\.displayReloadButton) { [weak self] displayReloadButton in
                guard let self = self else { return }
                self.navigationItem.leftBarButtonItems = displayReloadButton ? [self.itemReload] : []
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.isCollectionViewHidden, to: \.isHidden, on: collectionView)
            .store(in: &subscriptions)

        store.state
            .bind(\.emptyMessageViewTitle, to: \.title, on: emptyMessageView)
            .store(in: &subscriptions)
        store.state
            .bind(\.emptyMessageViewMessage, to: \.message, on: emptyMessageView)
            .store(in: &subscriptions)
        store.state
            .bind(\.emptyMessageViewAlpha, to: \.alpha, on: emptyMessageView)
            .store(in: &subscriptions)

        store.state
            .removeDuplicates(by: \.imageSources.selections)
            .sink { [weak self] state in self?.applySelection(state) }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard let self = self, isDismissed else { return }
                self.delegate?.didFinish(self)
            }
            .store(in: &subscriptions)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: ClipCreationViewState.Alert?) {
        switch alert {
        case let .error(title: title, message: message):
            presentErrorMessageAlertIfNeeded(title: title, message: message)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Snapshot

    private func makeSnapshot(_ state: ClipCreationViewState) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Layout.Item.tagAddition] + state.tags.orderedFilteredEntities().map({ Layout.Item.tag($0) }))

        snapshot.appendSections([.meta])
        snapshot.appendItems([
            .meta(.init(title: L10n.clipCreationViewMetaUrlTitle,
                        secondaryTitle: state.url?.absoluteString ?? L10n.clipCreationViewMetaUrlNo,
                        accessory: .button(title: L10n.clipCreationViewMetaUrlEdit))),
            .meta(.init(title: L10n.clipMetaShouldClip,
                        secondaryTitle: L10n.clipMetaShouldClipDescription,
                        accessory: .switch(isOn: state.shouldSaveAsClip))),
            .meta(.init(title: L10n.clipMetaShouldHides,
                        secondaryTitle: nil,
                        accessory: .switch(isOn: state.shouldSaveAsHiddenItem)))
        ])

        snapshot.appendSections([.image])
        snapshot.appendItems(state.imageSources.order.map({ Layout.Item.image($0) }))

        return snapshot
    }

    // MARK: Selection

    private func applySelection(_ state: ClipCreationViewState) {
        state.imageSources
            .selections
            .enumerated()
            .forEach { index, id in
                guard let indexPath = dataSource.indexPath(for: .image(id)) else { return }
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                guard let cell = collectionView.cellForItem(at: indexPath) as? ClipSelectionCollectionViewCell else { return }
                cell.selectionOrder = index + 1
            }
    }
}

// MARK: - Configuration

extension ClipCreationViewController {
    private func configureViewHierarchy() {
        view.backgroundColor = Asset.Color.background.color

        navigationItem.hidesBackButton = true
        navigationItem.title = L10n.clipCreationViewTitle
        [itemReload, itemDone].forEach {
            $0.setTitleTextAttributes([.foregroundColor: UIColor.lightGray], for: .disabled)
            $0.isEnabled = false
        }
        navigationItem.setRightBarButton(itemDone, animated: true)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: Layout.createLayout())
        collectionView.backgroundColor = .clear
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate(collectionView.constraints(fittingIn: view.safeAreaLayoutGuide))

        emptyMessageView.title = nil
        emptyMessageView.message = nil
        emptyMessageView.actionButtonTitle = L10n.clipCreationViewLoadingErrorAction
        emptyMessageView.delegate = self
        emptyMessageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyMessageView)
        NSLayoutConstraint.activate(emptyMessageView.constraints(fittingIn: view.safeAreaLayoutGuide))

        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate(overlayView.constraints(fittingIn: view))

        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.style = .large
        overlayView.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor)
        ])
    }

    private func configureDataSource() {
        let (proxy, dataSource) = Layout.configureDataSource(collectionView: collectionView,
                                                             cellDataSource: self,
                                                             thumbnailLoader: thumbnailLoader)
        self.dataSource = dataSource
        proxy.delegate = self
        self.proxy = proxy
    }
}

extension ClipCreationViewController: ClipSelectionCollectionViewCellDataSource {
    // MARK: ClipSelectionCollectionViewCellDataSource

    public var imageSources: [UUID: ImageSource] { store.stateValue.imageSources.imageSourceById }

    public func selectionOrder(of id: UUID) -> Int? {
        return store.stateValue.imageSources.selections.firstIndex(of: id)
    }

    public func shouldSaveAsClip() -> Bool {
        return store.stateValue.shouldSaveAsClip
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

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard case let .image(imageSourceId) = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.selected(imageSourceId))
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard case let .image(imageSourceId) = dataSource.itemIdentifier(for: indexPath) else { return }
        store.execute(.deselected(imageSourceId))
    }
}

extension ClipCreationViewController: EmptyMessageViewDelegate {
    // MARK: - EmptyMessageViewDelegate

    public func didTapActionButton(_ view: EmptyMessageView) {
        store.execute(.loadImages)
    }
}

extension ClipCreationViewController: TagSelectionViewControllerDelegate {
    // MARK: - TagSelectionViewControllerDelegate

    public func didSelectTags(tags: [Tag]) {
        store.execute(.tagsSelected(tags))
    }
}

extension ClipCreationViewController: ClipCreationViewDelegate {
    // MARK: - ClipCreationViewDelegate

    public func didSwitch(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool) {
        guard case let .meta(info) = dataSource.itemIdentifier(for: indexPath) else { return }
        switch info.title {
        case L10n.clipMetaShouldHides:
            store.execute(.shouldSaveAsHiddenItem(isOn))

        case L10n.clipMetaShouldClip:
            store.execute(.shouldSaveAsClip(isOn))

        default:
            break
        }
    }

    public func didTapButton(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
        if let url = store.stateValue.url {
            self.editUrlAlertContainer.present(
                withText: url.absoluteString,
                on: self,
                validator: { text in
                    guard let text = text else { return true }
                    return text.isEmpty || URL(string: text) != nil
                }, completion: { [weak self] action in
                    guard case let .saved(text: text) = action else { return }
                    self?.store.execute(.editedUrl(URL(string: text)))
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
                    self?.store.execute(.editedUrl(URL(string: text)))
                }
            )
        }
    }

    public func didTapTagAdditionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              case .tag = Layout.Section(rawValue: indexPath.section) else { return }
        self.presentTagSelectionView()
    }

    public func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
              case let .tag(tag) = self.dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }
        store.execute(.tagRemoveButtonTapped(tag.id))
    }

    private func presentTagSelectionView() {
        guard let parent = self.parent else { return }
        let selectedTags = Set(store.stateValue.tags.filteredEntities().map { $0.id })
        guard let nextVC = factory.makeTagSelectionViewController(selectedTags: selectedTags, delegate: self) else { return }
        parent.present(nextVC, animated: true, completion: nil)
    }
}
