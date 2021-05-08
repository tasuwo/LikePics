//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias Store = LikePics.Store<ClipPreviewPageViewState, ClipPreviewPageViewAction, ClipPreviewPageViewDependency>
    typealias CacheStore = LikePics.Store<ClipPreviewPageViewCacheState, ClipPreviewPageViewCacheAction, ClipPreviewPageViewCacheDependency>

    struct BarDependency: ClipPreviewPageBarDependency {
        weak var clipPreviewPageBarDelegate: ClipPreviewPageBarDelegate?
        var imageQueryService: ImageQueryServiceProtocol
        let transitionLock: TransitionLock
    }

    struct Context {
        let barState: ClipPreviewPageBarState
        let dependency: ClipPreviewPageViewDependency & HasImageQueryService
    }

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

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    private var cacheStore: CacheStore
    private var cacheSubscriptions: Set<AnyCancellable> = .init()

    private var previewVieSubscriptions: Set<AnyCancellable> = .init()

    private let factory: ViewControllerFactory

    // MARK: Temporary

    // super.init が呼ばれた時点で、initializer 内の 全処理が完了数前に viewDidLoad が呼び出されてしまうケースがある
    // 本来 initializer 内で行いたかった初期化処理を viewDidLoad 側に委譲するために一時的に保持するコンテキスト
    private var contextForViewDidLoad: Context?

    // MARK: - Initializers

    init(state: ClipPreviewPageViewState,
         barState: ClipPreviewPageBarState,
         cacheState: ClipPreviewPageViewCacheState,
         cacheController: ClipInformationViewCacheController,
         dependency: ClipPreviewPageViewDependency & HasImageQueryService,
         factory: ViewControllerFactory,
         transitionController: ClipPreviewPageTransitionControllerType)
    {
        struct CacheDependency: ClipPreviewPageViewCacheDependency {
            weak var informationViewCache: ClipInformationViewCaching?
        }

        self.store = Store(initialState: state, dependency: dependency, reducer: ClipPreviewPageViewReducer.self)
        self.cacheStore = CacheStore(initialState: cacheState,
                                     dependency: CacheDependency(informationViewCache: cacheController),
                                     reducer: ClipPreviewPageViewCacheReducer.self)
        self.cacheController = cacheController
        self.transitionController = transitionController
        self.factory = factory
        self.contextForViewDidLoad = .init(barState: barState, dependency: dependency)

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

        defer { self.contextForViewDidLoad = nil }

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
                self?.barController.store.execute(.stateChanged(state))
                self?.changePageIfNeeded(for: state)
            }
            .store(in: &subscriptions)

        store.state
            .bind(\.alert) { [weak self] alert in self?.presentAlertIfNeeded(for: alert) }
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

    private func changePageIfNeeded(for state: ClipPreviewPageViewState) {
        guard let currentItem = state.currentItem,
              currentIndex != state.currentIndex,
              let viewController = factory.makeClipPreviewViewController(for: currentItem, loadImageSynchronously: true)
        else {
            return
        }
        let direction = state.pageChange?.navigationDirection ?? .forward
        setViewControllers([viewController], direction: direction, animated: true, completion: { _ in
            self.didChangePage(to: viewController)
        })
    }

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
        guard let context = contextForViewDidLoad else { return }
        let barDependency = BarDependency(clipPreviewPageBarDelegate: self,
                                          imageQueryService: context.dependency.imageQueryService,
                                          transitionLock: context.dependency.transitionLock)
        barController = ClipPreviewPageBarController(state: context.barState, dependency: barDependency)
        barController.alertHostingViewController = self
        barController.barHostingViewController = self
    }
}

extension ClipPreviewPageViewController: ClipPreviewPageBarDelegate {
    // MARK: - ClipPreviewPageBarDelegate

    func didTriggered(_ event: ClipPreviewPageBarEvent) {
        store.execute(.barEventOccurred(event))
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
        return factory.makeClipPreviewViewController(for: item, loadImageSynchronously: false)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.item(after: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(for: item, loadImageSynchronously: false)
    }
}

extension ClipPreviewPageViewController: ClipPreviewPresentedAnimatorDataSource {
    // MARK: - ClipPreviewPresentedAnimatorDataSource

    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewView? {
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

    func animatingPageView(_ animator: ClipInformationAnimator) -> ClipPreviewView? {
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
