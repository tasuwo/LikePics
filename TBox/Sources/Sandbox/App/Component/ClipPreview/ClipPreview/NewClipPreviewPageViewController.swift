//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

class NewClipPreviewPageViewController: UIPageViewController {
    typealias Store = LikePics.Store<ClipPreviewPageViewState, ClipPreviewPageViewAction, ClipPreviewPageViewDependency>

    struct BarDependency: ClipPreviewPageBarDependency {
        weak var clipPreviewPageBarDelegate: ClipPreviewPageBarDelegate?
        var imageQueryService: ImageQueryServiceProtocol
    }

    // MARK: - Properties

    // MARK: View

    var currentViewController: ClipPreviewViewController? {
        return self.viewControllers?.first as? ClipPreviewViewController
    }

    var currentIndex: Int? {
        guard let viewController = currentViewController else { return nil }
        return store.stateValue.index(of: viewController.itemId)
    }

    var currentItemId: ClipItem.Identity? {
        return store.stateValue.currentItem?.id
    }

    private var isFullscreen = false {
        didSet {
            setNeedsStatusBarAppearanceUpdate()

            UIView.animate(withDuration: 0.2) {
                self.navigationController?.toolbar.isHidden = self.isFullscreen
                self.navigationController?.navigationBar.isHidden = self.isFullscreen
                self.parent?.view.backgroundColor = self.isFullscreen ? .black : Asset.Color.backgroundClient.color
            }
        }
    }

    private var transitionController: ClipPreviewPageTransitionControllerType!
    private var tapGestureRecognizer: UITapGestureRecognizer!

    override var prefersStatusBarHidden: Bool { isFullscreen }

    // MARK: Component

    private var barController: ClipPreviewPageBarController!

    // MARK: Store

    private var store: Store
    private var subscriptions: Set<AnyCancellable> = .init()

    private let factory: ViewControllerFactory

    // MARK: - Initializers

    init(state: ClipPreviewPageViewState,
         barState: ClipPreviewPageBarState,
         dependency: ClipPreviewPageViewDependency & HasImageQueryService,
         factory: ViewControllerFactory)
    {
        self.store = Store(initialState: state, dependency: dependency, reducer: ClipPreviewPageViewReducer.self)
        self.factory = factory

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            .interPageSpacing: state.interPageSpacing
        ])

        let barDependency = BarDependency(clipPreviewPageBarDelegate: self,
                                          imageQueryService: dependency.imageQueryService)
        barController = ClipPreviewPageBarController(state: barState, dependency: barDependency)

        addChild(barController)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureAppearance()
        configureGestureRecognizer()

        delegate = self
        dataSource = self

        barController.alertHostingViewController = self
        barController.barHostingViewController = self

        bind(to: store)

        store.execute(.viewDidLoad)
    }

    // MARK: - IBActions

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        isFullscreen = !isFullscreen
    }
}

// MARK: - Bind

extension NewClipPreviewPageViewController {
    private func bind(to store: Store) {
        store.state.sink { [weak self] state in
            guard let self = self else { return }

            self.isFullscreen = state.isFullscreen

            self.changePageIfNeeded(for: state)
            self.presentAlertIfNeeded(for: state.alert)

            if state.isDismissed {
                self.dismiss(animated: true, completion: nil)
            }
        }
        .store(in: &subscriptions)
    }

    private func changePageIfNeeded(for state: ClipPreviewPageViewState) {
        guard let currentItem = state.currentItem,
              currentIndex != state.currentIndex,
              let viewController = factory.makeClipPreviewViewController(itemId: currentItem.id, usesImageForPresentingAnimation: false)
        else {
            return
        }
        setViewControllers([viewController], direction: .forward, animated: false, completion: nil)
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
}

// MARK: - Configuration

extension NewClipPreviewPageViewController {
    private func configureAppearance() {
        navigationItem.title = ""
        modalTransitionStyle = .crossDissolve
    }

    private func configureGestureRecognizer() {
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGestureRecognizer)
    }
}

extension NewClipPreviewPageViewController: ClipPreviewPageBarDelegate {
    // MARK: - ClipPreviewPageBarDelegate

    func didTriggered(_ event: ClipPreviewPageBarEvent) {
        store.execute(.barEventOccurred(event))
    }
}

extension NewClipPreviewPageViewController: ClipPreviewPageViewDelegate {
    // MARK: - ClipPreviewPageViewDelegate

    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView) {
        isFullscreen = true
    }
}

extension NewClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard let index = currentIndex else { return }
        store.execute(.pageChanged(index: index))
    }
}

extension NewClipPreviewPageViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.item(before: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(itemId: item.id, usesImageForPresentingAnimation: false)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let item = store.stateValue.item(after: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(itemId: item.id, usesImageForPresentingAnimation: false)
    }
}
