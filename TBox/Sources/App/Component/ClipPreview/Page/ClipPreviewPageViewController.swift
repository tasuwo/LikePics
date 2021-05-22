//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias RootState = ClipPreviewPageViewRootState
    typealias RootAction = ClipPreviewPageViewRootAction
    typealias RootDependency = ClipPreviewPageViewRootDependency
    typealias RootStore = LikePics.Store<RootState, RootAction, RootDependency>

    typealias Store = AnyStoring<ClipPreviewPageViewState, ClipPreviewPageViewAction, ClipPreviewPageViewDependency>
    typealias CacheStore = AnyStoring<ClipPreviewPageViewCacheState, ClipPreviewPageViewCacheAction, ClipPreviewPageViewCacheDependency>

    // MARK: - Properties

    // MARK: View

    private var currentViewController: ClipPreviewViewController? {
        return self.viewControllers?.first as? ClipPreviewViewController
    }

    private var currentIndex: Int? {
        guard let viewController = currentViewController else { return nil }
        return store.stateValue.index(of: viewController.itemId)
    }

    private let transitionController: ClipPreviewPageTransitionControllerType
    private var tapGestureRecognizer: UITapGestureRecognizer!

    override var prefersStatusBarHidden: Bool { barController.store.stateValue.isFullscreen }

    // MARK: Component

    private var barController: ClipPreviewPageBarController!
    private let cacheController: ClipInformationViewCacheController

    // MARK: Service

    private let router: Router
    private let factory: ViewControllerFactory

    // MARK: Store

    private var rootStore: RootStore

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    private var cacheStore: CacheStore
    private var cacheSubscriptions: Set<AnyCancellable> = .init()

    private var previewVieSubscriptions: Set<AnyCancellable> = .init()
    private var modalSubscription: Cancellable?

    // MARK: - Initializers

    init(state: ClipPreviewPageViewRootState,
         cacheController: ClipInformationViewCacheController,
         dependency: ClipPreviewPageViewRootDependency,
         factory: ViewControllerFactory,
         transitionController: ClipPreviewPageTransitionControllerType)
    {
        struct CacheDependency: ClipPreviewPageViewCacheDependency {
            weak var informationViewCache: ClipInformationViewCaching?
        }

        let rootStore = RootStore(initialState: state, dependency: dependency, reducer: clipPreviewPageViewRootReducer)
        self.rootStore = rootStore

        self.store = rootStore
            .proxy(RootState.pageConverter, RootAction.pageConverter)
            .eraseToAnyStoring()
        self.cacheStore = rootStore
            .proxy(RootState.cacheConverter, RootAction.cacheConverter)
            .eraseToAnyStoring()
        let barStore: ClipPreviewPageBarController.Store = rootStore
            .proxy(RootState.barConverter, RootAction.barConverter)
            .eraseToAnyStoring()
        self.barController = ClipPreviewPageBarController(store: barStore, imageQueryService: dependency.imageQueryService)

        self.cacheController = cacheController
        self.transitionController = transitionController
        self.factory = factory

        self.router = dependency.router

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [.interPageSpacing: 40])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.barController.traitCollectionDidChange(to: self.view.traitCollection)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cacheStore.execute(.viewWillDisappear)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        barController.viewDidAppear()

        cacheStore.execute(.viewDidAppear)

        // HACK: 別画面表示 > rotate > この画面に戻る、といった操作をすると、SizeClassの不整合が生じるため、表示時に同期させる
        barController.traitCollectionDidChange(to: self.view.traitCollection)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViewHierarchy()
        configureGestureRecognizer()
        configureBarController()

        delegate = self
        dataSource = self

        cacheController.informationView.dataSource = self

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
                self?.dismiss(animated: true, completion: nil)
            }
            .store(in: &subscriptions)

        transitionController.outputs.presentInformation
            .sink { [weak self] in self?.store.execute(.clipInformationViewPresented) }
            .store(in: &subscriptions)
    }

    // MARK: Page

    private func changePageIfNeeded(for state: ClipPreviewPageViewState) {
        guard let currentItem = state.currentItem,
              currentIndex != state.currentIndex,
              let viewController = factory.makeClipPreviewViewController(for: currentItem)
        else {
            return
        }
        let direction = state.pageChange?.navigationDirection ?? .forward
        setViewControllers([viewController], direction: direction, animated: true, completion: { _ in
            self.didChangePage(to: viewController)
        })
    }

    private func didChangePage(to viewController: ClipPreviewViewController) {
        tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
        viewController.previewView.delegate = self

        previewVieSubscriptions.forEach { $0.cancel() }
        viewController.previewView.isInitialZoomScale
            .sink { [weak self] isInitialZoomScale in
                self?.transitionController.inputs.isInitialPreviewZoomScale.send(isInitialZoomScale)
            }
            .store(in: &previewVieSubscriptions)
        viewController.previewView.contentOffset
            .sink { [weak self] offset in
                self?.transitionController.inputs.previewContentOffset.send(offset)
            }
            .store(in: &previewVieSubscriptions)
        transitionController.inputs.previewPanGestureRecognizer.send(viewController.previewView.panGestureRecognizer)

        cacheStore.execute(.pageChanged(store.stateValue.clipId, viewController.itemId))
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
        case .albumSelection:
            presentAlbumSelectionModal()

        case let .tagSelection(tagIds: selections):
            presentTagSelectionModal(selections: selections)

        case .none:
            break
        }
    }

    private func presentAlbumSelectionModal() {
        let id = UUID()

        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .albumSelectionModal)
            .sink { [weak self] notification in
                let albumId = notification.userInfo?[ModalNotification.UserInfoKey.selectedAlbumId] as? Album.Identity
                self?.store.execute(.albumsSelected(albumId))
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showAlbumSelectionModal(id: id) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }

    private func presentTagSelectionModal(selections: Set<Tag.Identity>) {
        let id = UUID()

        modalSubscription = ModalNotificationCenter.default
            .publisher(for: id, name: .tagSelectionModal)
            .sink { [weak self] notification in
                if let tags = notification.userInfo?[ModalNotification.UserInfoKey.selectedTags] as? Set<Tag> {
                    self?.store.execute(.tagsSelected(Set(tags.map({ $0.id }))))
                } else {
                    self?.store.execute(.tagsSelected(nil))
                }
                self?.modalSubscription?.cancel()
                self?.modalSubscription = nil
            }

        if router.showTagSelectionModal(id: id, selections: selections) == false {
            modalSubscription?.cancel()
            modalSubscription = nil
            store.execute(.modalCompleted(false))
        }
    }
}

// MARK: - Configuration

extension ClipPreviewPageViewController {
    private func configureViewHierarchy() {
        navigationItem.title = ""
        modalTransitionStyle = .crossDissolve

        view.insertSubview(cacheController.baseView, at: 0)
        NSLayoutConstraint.activate(cacheController.baseView.constraints(fittingIn: view))
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
}

extension ClipPreviewPageViewController: ClipPreviewPageViewDelegate {
    // MARK: - ClipPreviewPageViewDelegate

    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView) {
        barController.store.execute(.willBeginZoom)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let viewController = currentViewController, let index = currentIndex else { return }
        didChangePage(to: viewController)
        store.execute(.pageChanged(index: index))
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.item(before: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(for: item)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.item(after: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(for: item)
    }
}

extension ClipPreviewPageViewController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPreviewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return currentViewController?.previewView
    }

    func isCurrentItemPrimary(_ animator: ClipPreviewAnimator) -> Bool {
        view.layoutIfNeeded()
        return store.stateValue.currentIndex == 0
    }

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let pageView = currentViewController?.previewView else { return .zero }
        // HACK: SplitMode 時にサイズが合わない問題を修正
        pageView.frame = containerView.frame
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }
}

extension ClipPreviewPageViewController: ClipInformationPresentingAnimatorDataSource {
    // MARK: - ClipInformationPresentingAnimatorDataSource

    func animatingPreviewView(_ animator: ClipInformationAnimator) -> ClipPreviewView? {
        view.layoutIfNeeded()
        return currentViewController?.previewView
    }

    func baseView(_ animator: ClipInformationAnimator) -> UIView? {
        return view
    }

    func componentsOverBaseView(_ animator: ClipInformationAnimator) -> [UIView] {
        return ([navigationController?.navigationBar, navigationController?.toolbar] as [UIView?]).compactMap { $0 }
    }

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect {
        view.layoutIfNeeded()
        guard let pageView = currentViewController?.previewView else { return .zero }
        return pageView.convert(pageView.initialImageFrame, to: containerView)
    }

    func set(_ animator: ClipInformationAnimator, isUserInteractionEnabled: Bool) {
        view.isUserInteractionEnabled = isUserInteractionEnabled
    }
}

extension ClipPreviewPageViewController: ClipInformationViewDataSource {
    // MARK: - ClipInformationViewDataSource

    func previewImage(_ view: ClipInformationView) -> UIImage? {
        return self.currentViewController?.previewView.image
    }

    func previewPageBounds(_ view: ClipInformationView) -> CGRect {
        return self.currentViewController?.previewView.bounds ?? .zero
    }
}
