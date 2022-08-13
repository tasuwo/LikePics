//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import Smoothie
import UIKit

public class ClipCreationViewController: UIViewController {
    // MARK: - Type Aliases

    typealias Layout = ClipCreationViewLayout
    typealias Store = CompositeKit.Store<ClipCreationViewState, ClipCreationViewAction, ClipCreationViewDependency>
    public typealias ModalRouter = TagSelectionModalRouter & AlbumMultiSelectionModalRouter

    // MARK: - Properties

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

    private let modalRouter: ModalRouter
    private let thumbnailPipeline: Pipeline
    private let imageLoader: ImageLoadable

    // MARK: Store/Subscription

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()
    private var modalSubscriptions: Set<AnyCancellable> = .init()
    private let clipsUpdateQueue = DispatchQueue(label: "net.tasuwo.TBoxCore.ClipCreationViewController", qos: .userInteractive)

    // MARK: - Initializers

    public init(state: ClipCreationViewState,
                dependency: ClipCreationViewDependency,
                thumbnailPipeline: Pipeline,
                imageLoader: ImageLoadable,
                modalRouter: ModalRouter)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipCreationViewReducer())
        self.thumbnailPipeline = thumbnailPipeline
        self.imageLoader = imageLoader
        self.modalRouter = modalRouter
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
            .removeDuplicates(by: \.imageLoadSources.selections)
            .sink { [weak self] state in self?.applySelection(state) }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
            .store(in: &subscriptions)

        store.state
            .bind(\.modal) { [weak self] modal in self?.presentModalIfNeeded(for: modal) }
            .store(in: &subscriptions)

        store.state
            .bind(\.isDismissed) { [weak self] isDismissed in
                guard isDismissed else { return }
                self?.dismissAll(completion: nil)
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

    // MARK: Modal

    private func presentModalIfNeeded(for modal: ClipCreationViewState.Modal?) {
        switch modal {
        case let .albumSelection(id: id, albumIds: albumIds):
            presentAlbumSelectionModal(id: id, selections: albumIds)

        case let .tagSelection(id: id, tagIds: tagIds):
            presentTagSelectionModal(id: id, selections: tagIds)

        case .none:
            break
        }
    }

    private func presentAlbumSelectionModal(id: UUID, selections: Set<Album.Identity>) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .albumMultiSelectionModalDidSelect)
            .sink { [weak self] notification in
                let albums = notification.userInfo?[ModalNotification.UserInfoKey.selectedAlbums] as? [ListingAlbumTitle]
                self?.store.execute(.albumsSelected(albums))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        ModalNotificationCenter.default
            .publisher(for: id, name: .albumMultiSelectionModalDidDismiss)
            .sink { [weak self] _ in
                self?.modalSubscriptions.removeAll()
                self?.store.execute(.modalCompleted(false))
            }
            .store(in: &modalSubscriptions)

        if modalRouter.showAlbumMultiSelectionModal(id: id, selections: selections) == false {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }

    private func presentTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModalDidSelect)
            .sink { [weak self] notification in
                let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? [Tag]
                self?.store.execute(.tagsSelected(tags))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModalDidDismiss)
            .sink { [weak self] _ in
                self?.modalSubscriptions.removeAll()
                self?.store.execute(.modalCompleted(false))
            }
            .store(in: &modalSubscriptions)

        if modalRouter.showTagSelectionModal(id: id, selections: selections) == false {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }

    // MARK: Snapshot

    private func makeSnapshot(_ state: ClipCreationViewState) -> Layout.Snapshot {
        var snapshot = Layout.Snapshot()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Layout.Item.tagAddition] + state.tags.orderedFilteredEntities().map({ Layout.Item.tag($0) }))

        snapshot.appendSections([.album])
        snapshot.appendItems(state.albums.orderedFilteredEntities().map({ Layout.Item.album($0) }))

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
        snapshot.appendItems(state.imageLoadSources.order.map({ Layout.Item.image($0) }))

        return snapshot
    }

    // MARK: Selection

    private func applySelection(_ state: ClipCreationViewState) {
        zip(state.imageLoadSources.selections.indices, state.imageLoadSources.selections)
            .forEach { index, id in
                guard let indexPath = dataSource.indexPath(for: .image(id)) else { return }
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                guard let cell = collectionView.cellForItem(at: indexPath) as? ClipSelectionCollectionViewCell else { return }
                cell.selectionOrder = index + 1
                cell.displaySelectionOrder = state.shouldSaveAsClip
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
            // HACK: ShareExtentionだと、tintColorがテキスト色にうまく反映されないケースがあるので、ここで反映する
            $0.setTitleTextAttributes([.foregroundColor: Asset.Color.likePicsRed.color], for: .normal)
            $0.setTitleTextAttributes([.foregroundColor: UIColor.lightGray.withAlphaComponent(0.6)], for: .disabled)
            $0.isEnabled = false
        }
        navigationItem.setRightBarButton(itemDone, animated: true)

        let layout = Layout.createLayout(albumTrailingSwipeActionProvider: { [weak self] indexPath in
            guard let self = self else { return nil }
            guard case let .album(album) = self.dataSource.itemIdentifier(for: indexPath) else { return nil }
            let deleteAction = UIContextualAction(style: .destructive, title: L10n.AlbumSection.SwipeAction.delete, handler: { _, _, completion in
                self.store.execute(.tapAlbumDeletionButton(album.id, completion: completion))
            })
            return UISwipeActionsConfiguration(actions: [deleteAction])
        })
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
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
                                                             thumbnailPipeline: thumbnailPipeline,
                                                             imageLoader: imageLoader,
                                                             albumEditHandler: { [weak self] in self?.store.execute(.tapAlbumAdditionButton) })
        self.dataSource = dataSource
        proxy.delegate = self
        self.proxy = proxy
    }
}

extension ClipCreationViewController: ClipSelectionCollectionViewCellDataSource {
    // MARK: ClipSelectionCollectionViewCellDataSource

    public var imageSources: [UUID: ImageLoadSource] { store.stateValue.imageLoadSources.imageLoadSourceById }

    public func selectionOrder(of id: UUID) -> Int? {
        return store.stateValue.imageLoadSources.selections.firstIndex(of: id)
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
        store.execute(.tapTagAdditionButton)
    }

    public func didTapTagDeletionButton(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell),
              case let .tag(tag) = self.dataSource.itemIdentifier(for: indexPath)
        else {
            return
        }
        store.execute(.tagRemoveButtonTapped(tag.id))
    }
}

extension ClipCreationViewController: UIAdaptivePresentationControllerDelegate {
    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        store.execute(.didDismissedManually)
    }
}

extension ClipCreationViewController: ModalController {
    // MARK: - ModalController

    public var id: UUID { store.stateValue.id }
}
