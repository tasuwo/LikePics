//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import LikePicsUIKit
import MobileTransition
import TagSelectionModalFeature
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias RootState = ClipPreviewPageViewRootState
    typealias RootAction = ClipPreviewPageViewRootAction
    typealias RootDependency = ClipPreviewPageViewRootDependency
    typealias RootStore = CompositeKit.Store<RootState, RootAction, RootDependency>

    typealias Store = AnyStoring<ClipPreviewPageViewState, ClipPreviewPageViewAction, ClipPreviewPageViewDependency>

    typealias ModalRouter = AlbumSelectionModalRouter & ClipItemListModalRouter & ClipPreviewPlayConfigurationModalRouter & TagSelectionModalRouter

    // MARK: - Properties

    // MARK: View

    private var currentViewController: ClipPreviewViewController? {
        return self.viewControllers?.first as? ClipPreviewViewController
    }

    private var currentIndexPath: ClipCollection.IndexPath? {
        guard let viewController = currentViewController else { return nil }
        return store.stateValue.clips.indexPath(ofItemHaving: viewController.itemId)
    }

    private let transitionDispatcher: ClipPreviewPageTransitionDispatcherType
    private var tapGestureRecognizer: UITapGestureRecognizer!

    override var prefersStatusBarHidden: Bool { barController.store.stateValue.isFullscreen }

    // MARK: Component

    private var barController: ClipPreviewPageBarController!

    // MARK: Service

    private let modalRouter: ModalRouter
    private let factory: ViewControllerFactory
    private let previewPrefetcher: PreviewPrefetchable

    // MARK: Store

    private var rootStore: RootStore

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    private var previewViewSubscriptions: Set<AnyCancellable> = .init()
    private var modalSubscriptions: Set<AnyCancellable> = .init()
    private var nextPreviewPrefetchCancellable: PreviewPrefetchCancellable?
    private var prevPreviewPrefetchCancellable: PreviewPrefetchCancellable?

    private let itemListTransitionController: ClipItemListTransitioningControllable

    // MARK: State Restoration

    private let appBundle: Bundle

    // MARK: - Initializers

    init(state: ClipPreviewPageViewRootState,
         dependency: ClipPreviewPageViewRootDependency,
         factory: ViewControllerFactory,
         previewPrefetcher: PreviewPrefetchable,
         transitionDispatcher: ClipPreviewPageTransitionDispatcherType,
         itemListTransitionController: ClipItemListTransitioningControllable,
         modalRouter: ModalRouter,
         appBundle: Bundle)
    {
        let rootStore = RootStore(initialState: state, dependency: dependency, reducer: clipPreviewPageViewRootReducer)
        self.rootStore = rootStore

        self.store = rootStore
            .proxy(RootState.mappingToPage, RootAction.pageMapping)
            .eraseToAnyStoring()
        let barStore: ClipPreviewPageBarController.Store = rootStore
            .proxy(RootState.mappingToBar, RootAction.barMapping)
            .eraseToAnyStoring()
        self.barController = ClipPreviewPageBarController(store: barStore, imageQueryService: dependency.imageQueryService)

        self.transitionDispatcher = transitionDispatcher
        self.factory = factory
        self.previewPrefetcher = previewPrefetcher

        self.modalRouter = modalRouter

        self.itemListTransitionController = itemListTransitionController

        self.appBundle = appBundle

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 40])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - View Life-Cycle Methods

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.barController.traitCollectionDidChange(to: self.view.traitCollection)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        barController.viewDidAppear()

        // HACK: 別画面表示 > rotate > この画面に戻る、といった操作をすると、SizeClassの不整合が生じるため、表示時に同期させる
        barController.traitCollectionDidChange(to: self.view.traitCollection)

        updateUserActivity()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureGestureRecognizer()
        configureBarController()
        configureKeybinding()

        delegate = self
        dataSource = self

        bind(to: store)
        barController.viewDidLoad()

        store.execute(.viewDidLoad)
        barController.traitCollectionDidChange(to: view.traitCollection)
    }

    // MARK: - IBActions

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        barController.store.execute(.didTapView)
    }
}

// MARK: User Activity

extension ClipPreviewPageViewController {
    private func updateUserActivity() {
        guard case let .clips(state, preview: _) = view.window?.windowScene?.userActivity?.intent(appBundle: appBundle) else { return }
        DispatchQueue.global().async {
            guard let activity = NSUserActivity.make(with: .clips(state, preview: self.store.stateValue.currentIndexPath), appBundle: self.appBundle) else { return }
            DispatchQueue.main.async { self.view.window?.windowScene?.userActivity = activity }
        }
    }
}

// MARK: - Bind

extension ClipPreviewPageViewController {
    private func bind(to store: Store) {
        store.state
            .removeDuplicates()
            .sink { [weak self] state in
                self?.changePageIfNeeded(for: state)
            }
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

        store.state
            .bind(\.currentIndexPath) { [weak self] indexPath in
                self?.barController.store.execute(.updatedCurrentIndex(indexPath.itemIndex))
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.currentClip) { [weak self] currentClip in
                guard let items = currentClip?.items else { return }
                self?.barController.store.execute(.updatedClipItems(items))
            }
            .store(in: &subscriptions)

        store.state
            .sink { [weak self] state in
                guard let self = self, let item = state.currentItem else { return }
                if let nextItem = state.clips.pickNextVisibleItem(ofItemHaving: item.id) {
                    self.nextPreviewPrefetchCancellable = self.previewPrefetcher.prefetchPreview(for: nextItem)
                }
                if let prevItem = state.clips.pickNextVisibleItem(ofItemHaving: item.id) {
                    self.prevPreviewPrefetchCancellable = self.previewPrefetcher.prefetchPreview(for: prevItem)
                }
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.playingAt) { [weak self] playingAt in
                UIApplication.shared.isIdleTimerDisabled = playingAt != nil
                self?.barController.store.execute(.updatedPlaying(playingAt != nil))
            }
            .store(in: &subscriptions)

        transitionDispatcher.outputs.presentInformation
            .sink { [weak self] in self?.store.execute(.clipInformationViewPresented) }
            .store(in: &subscriptions)

        transitionDispatcher.outputs.didBeginPan
            .sink { [weak self] in self?.store.execute(.didBeginPan) }
            .store(in: &subscriptions)
    }

    // MARK: Page

    private func changePageIfNeeded(for state: ClipPreviewPageViewState) {
        guard let nextItem = state.currentItem,
              currentViewController?.itemId != nextItem.id,
              let viewController = factory.makeClipPreviewViewController(for: nextItem)
        else {
            return
        }
        let direction = state.pageChange?.navigationDirection ?? .forward

        setViewControllers([viewController], direction: direction, animated: state.isPageAnimated, completion: { _ in
            self.didChangePage(to: viewController)
        })
    }

    private func didChangePage(to viewController: ClipPreviewViewController) {
        tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
        viewController.previewView.delegate = self

        previewViewSubscriptions.forEach { $0.cancel() }
        viewController.previewView.isInitialZoomScale
            .sink { [weak self] isInitialZoomScale in
                self?.transitionDispatcher.inputs.isInitialPreviewZoomScale.send(isInitialZoomScale)
            }
            .store(in: &previewViewSubscriptions)
        viewController.previewView.contentOffset
            .sink { [weak self] offset in
                self?.transitionDispatcher.inputs.previewContentOffset.send(offset)
            }
            .store(in: &previewViewSubscriptions)
        transitionDispatcher.inputs.previewPanGestureRecognizer.send(viewController.previewView.panGestureRecognizer)
    }

    // MARK: Alert

    private func presentAlertIfNeeded(for alert: ClipPreviewPageViewState.Alert?) {
        switch alert {
        case let .error(message):
            presentErrorMessageAlertIfNeeded(message: message)

        case .none:
            break
        }
    }

    private func presentErrorMessageAlertIfNeeded(message: String?) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default) { [weak self] _ in
            self?.store.execute(.alertDismissed)
        })
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Modal

    private func presentModalIfNeeded(for modal: ClipPreviewPageViewState.Modal?) {
        switch modal {
        case let .clipItemList(id: id):
            presentClipItemListModal(id: id)

        case let .albumSelection(id: id):
            presentAlbumSelectionModal(id: id)

        case let .tagSelection(id: id, tagIds: selections):
            presentTagSelectionModal(id: id, selections: selections)

        case let .playConfig(id: id):
            presentPlayConfigModal(id: id)

        case .none:
            break
        }
    }

    private func presentClipItemListModal(id: UUID) {
        guard let clip = store.stateValue.currentClip else { return }

        ModalNotificationCenter.default
            .publisher(for: id, name: .clipItemList)
            .sink { [weak self] notification in
                let itemId = notification.userInfo?[ModalNotification.UserInfoKey.selectedPreviewItem] as? ClipItem.Identity
                self?.store.execute(.itemRequested(itemId))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        let succeeded = modalRouter.showClipItemListModal(id: id,
                                                          clipId: clip.id,
                                                          clipItems: clip.items,
                                                          transitioningController: itemListTransitionController)
        if !succeeded {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }

    private func presentAlbumSelectionModal(id: UUID) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .albumSelectionModal)
            .sink { [weak self] notification in
                let albumId = notification.userInfo?[ModalNotification.UserInfoKey.selectedAlbumId] as? Album.Identity
                self?.store.execute(.albumsSelected(albumId))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        ModalNotificationCenter.default
            .publisher(for: id, name: .albumSelectionModalDidDismiss)
            .sink { [weak self] _ in
                self?.store.execute(.modalCompleted(false))
                self?.modalSubscriptions.removeAll()
            }
            .store(in: &modalSubscriptions)

        if modalRouter.showAlbumSelectionModal(id: id) == false {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }

    private func presentTagSelectionModal(id: UUID, selections: Set<Tag.Identity>) {
        ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModalDidSelect)
            .sink { [weak self] notification in
                if let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? [Tag] {
                    self?.store.execute(.tagsSelected(Set(tags.map({ $0.id }))))
                } else {
                    self?.store.execute(.tagsSelected(nil))
                }
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

    private func presentPlayConfigModal(id: UUID) {
        let succeeded = modalRouter.showClipPreviewPlayConfigurationModal(id: id)

        ModalNotificationCenter.default
            .publisher(for: id, name: .clipPreviewPlayConfigurationModalDidDismiss)
            .sink { [weak self] _ in
                self?.modalSubscriptions.removeAll()
                self?.store.execute(.modalCompleted(false))
            }
            .store(in: &modalSubscriptions)

        if !succeeded {
            modalSubscriptions.removeAll()
            store.execute(.modalCompleted(false))
        }
    }
}

// MARK: - Configuration

extension ClipPreviewPageViewController {
    private func configureViewHierarchy() {
        navigationItem.title = ""
        modalTransitionStyle = .crossDissolve
    }

    private func configureGestureRecognizer() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGestureRecognizer)
    }

    private func configureBarController() {
        barController.alertHostingViewController = self
        barController.barHostingViewController = self
    }

    private func configureKeybinding() {
        let upKeyCommand = UIKeyCommand(title: L10n.ClipPreview.KeyCommand.detail, action: #selector(handle(key:)), input: UIKeyCommand.inputUpArrow, modifierFlags: [])
        upKeyCommand.wantsPriorityOverSystemBehavior = true
        addKeyCommand(upKeyCommand)

        let leftKeyCommand = UIKeyCommand(title: L10n.ClipPreview.KeyCommand.backward, action: #selector(handle(key:)), input: UIKeyCommand.inputLeftArrow, modifierFlags: [])
        leftKeyCommand.wantsPriorityOverSystemBehavior = true
        addKeyCommand(leftKeyCommand)

        let rightKeyCommand = UIKeyCommand(title: L10n.ClipPreview.KeyCommand.forward, action: #selector(handle(key:)), input: UIKeyCommand.inputRightArrow, modifierFlags: [])
        rightKeyCommand.wantsPriorityOverSystemBehavior = true
        addKeyCommand(rightKeyCommand)

        let downKeyCommand = UIKeyCommand(title: L10n.ClipPreview.KeyCommand.back, action: #selector(handle(key:)), input: UIKeyCommand.inputDownArrow, modifierFlags: [])
        downKeyCommand.wantsPriorityOverSystemBehavior = true
        addKeyCommand(downKeyCommand)
    }

    @objc func handle(key: UIKeyCommand?) {
        switch key?.input {
        case UIKeyCommand.inputUpArrow: store.execute(.inputUpArrow)
        case UIKeyCommand.inputLeftArrow: store.execute(.inputLeftArrow)
        case UIKeyCommand.inputRightArrow: store.execute(.inputRightArrow)
        case UIKeyCommand.inputDownArrow: store.execute(.inputDownArrow)
        default: break
        }
    }
}

extension ClipPreviewPageViewController: ClipPreviewPageViewDelegate {
    // MARK: - ClipPreviewPageViewDelegate

    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView) {
        store.execute(.willBeginZoom)
        barController.store.execute(.willBeginZoom)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        store.execute(.willBeginTransition)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = currentViewController, let indexPath = currentIndexPath else { return }
        didChangePage(to: viewController)
        store.execute(.pageChanged(indexPath: indexPath))
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.clips.pickPreviousVisibleItem(ofItemHaving: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(for: item)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.clips.pickNextVisibleItem(ofItemHaving: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(for: item)
    }
}

extension ClipPreviewPageViewController: ClipPreviewPresenting {
    // MARK: - ClipPreviewPresenting

    func previewingClipItem(_ animator: ClipPreviewAnimator) -> PreviewingClipItem? {
        guard let clip = store.stateValue.currentClip,
              let item = store.stateValue.currentItem else { return nil }
        return .init(clipId: clip.id,
                     itemId: item.id,
                     imageSize: item.imageSize,
                     isItemPrimary: clip.items.first == item)
    }

    func previewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return currentViewController?.previewView
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let previewView = currentViewController?.previewView else { return .zero }
        // HACK: SplitMode 時にサイズが合わない問題を修正
        previewView.frame = containerView.frame
        return previewView.convert(previewView.initialImageFrame, to: containerView)
    }
}

extension ClipPreviewPageViewController: ClipItemListPresentable {
    // MARK: - ClipItemListPresentable

    func previewingClipItem(_ animator: ClipItemListAnimator) -> PreviewingClipItem? {
        guard let clip = store.stateValue.currentClip,
              let item = store.stateValue.currentItem else { return nil }
        return .init(clipId: clip.id,
                     itemId: item.id,
                     imageSize: item.imageSize,
                     isItemPrimary: clip.items.first == item)
    }

    func previewView(_ animator: ClipItemListAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return currentViewController?.previewView
    }

    func clipItemListAnimator(_ animator: ClipItemListAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let previewView = currentViewController?.previewView else { return .zero }
        // HACK: SplitMode 時にサイズが合わない問題を修正
        previewView.frame = containerView.frame
        return previewView.convert(previewView.initialImageFrame, to: containerView)
    }
}

extension ClipPreviewPageViewController: ClipItemInformationPresentable {
    // MARK: - ClipItemInformationPresentable

    func isPreviewing(_ animator: ClipItemInformationAnimator, clipItem: InfoViewingClipItem) -> Bool {
        guard let indexPath = store.stateValue.clips.indexPath(ofItemHaving: clipItem.itemId) else {
            return false
        }
        return store.stateValue.currentIndexPath == indexPath
    }

    func previewView(_ animator: ClipItemInformationAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return currentViewController?.previewView
    }

    func baseView(_ animator: ClipItemInformationAnimator) -> UIView? {
        return view
    }

    func componentsOverBaseView(_ animator: ClipItemInformationAnimator) -> [UIView] {
        return ([navigationController?.navigationBar, navigationController?.toolbar] as [UIView?]).compactMap { $0 }
    }

    func clipItemInformationAnimator(_ animator: ClipItemInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let pageView = currentViewController?.previewView else { return .zero }
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }

    func set(_ animator: ClipItemInformationAnimator, isUserInteractionEnabled: Bool) {
        view.isUserInteractionEnabled = isUserInteractionEnabled
    }
}
