//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import TBoxCore
import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias Factory = ViewControllerFactory

    enum TransitionDestination {
        case back
        case information
    }

    private let factory: Factory
    private let presenter: ClipPreviewPagePresenter
    private let barItemsProvider: ClipPreviewPageBarButtonItemsProvider
    private let previewTransitioningController: ClipPreviewTransitionControllerProtocol
    private let informationTransitioningController: ClipInformationTransitioningControllerProtocol

    private var destination: TransitionDestination?

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var panGestureRecognizer: UIPanGestureRecognizer!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var tapGestureRecognizer: UITapGestureRecognizer!

    private var isFullscreen = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()

            UIView.animate(withDuration: 0.2) {
                self.navigationController?.toolbar.isHidden = self.isFullscreen
                self.navigationController?.navigationBar.isHidden = self.isFullscreen
                self.parent?.view.backgroundColor = self.isFullscreen ? .black : Asset.backgroundClient.color
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return self.isFullscreen
    }

    var currentIndex: Int? {
        guard let currentViewController = self.currentViewController else { return nil }
        return self.resolveIndex(of: currentViewController)
    }

    var currentViewController: ClipItemPreviewViewController? {
        return self.viewControllers?.first as? ClipItemPreviewViewController
    }

    // MARK: - Lifecycle

    init(factory: Factory,
         presenter: ClipPreviewPagePresenter,
         barItemsProvider: ClipPreviewPageBarButtonItemsProvider,
         previewTransitioningController: ClipPreviewTransitionControllerProtocol,
         informationTransitionController: ClipInformationTransitioningController)
    {
        self.factory = factory
        self.presenter = presenter
        self.barItemsProvider = barItemsProvider
        self.previewTransitioningController = previewTransitioningController
        self.informationTransitioningController = informationTransitionController

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 40
        ])

        self.presenter.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
        self.dataSource = self

        self.setupAppearance()
        self.setupBar()
        self.setupGestureRecognizer()

        self.presenter.setup()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.barItemsProvider.onUpdateOrientation()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.navigationItem.title = ""
        self.modalTransitionStyle = .crossDissolve
    }

    // MARK: Bar

    private func setupBar() {
        self.barItemsProvider.alertPresentable = self
        self.barItemsProvider.delegate = self
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.panGestureRecognizer)

        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        self.tapGestureRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }

    @objc
    func didPan(_ sender: UIPanGestureRecognizer) {
        switch (sender.state, self.destination) {
        case (.began, .back):
            self.currentViewController?.previewView.isScrollEnabled = false
            self.previewTransitioningController.beginTransition(.custom(interactive: true))
            self.dismiss(animated: true, completion: nil)

        case (.ended, .back):
            if self.previewTransitioningController.isInteractive {
                self.currentViewController?.previewView.isScrollEnabled = true
                self.previewTransitioningController.didPanForDismissal(sender: sender)
            }
            self.destination = nil

        case (_, .back):
            if self.previewTransitioningController.isInteractive {
                self.previewTransitioningController.didPanForDismissal(sender: sender)
            }

        case (.began, .information):
            guard let index = self.currentIndex, self.presenter.clip.items.indices.contains(index) else { return }
            let nullableViewController = self.factory.makeClipInformationViewController(
                clipId: self.presenter.clip.identity,
                itemId: self.presenter.clip.items[index].identity,
                transitioningController: self.informationTransitioningController,
                dataSource: self
            )
            guard let viewController = nullableViewController else { return }
            self.informationTransitioningController.beginTransition(.custom(interactive: true))
            self.present(viewController, animated: true, completion: nil)

        case (.ended, .information):
            if self.informationTransitioningController.isInteractive {
                self.informationTransitioningController.didPanForPresentation(sender: sender)
            }
            self.destination = nil

        case (_, .information):
            if self.informationTransitioningController.isInteractive {
                self.informationTransitioningController.didPanForPresentation(sender: sender)
            }

        case (_, .none):
            break
        }
    }

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        self.isFullscreen = !self.isFullscreen
    }

    // MARK: Page resolution

    private func resolveIndex(of viewController: UIViewController) -> Int? {
        guard let viewController = viewController as? ClipItemPreviewViewController else { return nil }
        guard let currentIndex = self.presenter.clip.items.firstIndex(where: { $0.identity == viewController.itemId }) else { return nil }
        return currentIndex
    }

    private func makeViewController(at index: Int) -> UIViewController? {
        guard self.presenter.clip.items.indices.contains(index) else { return nil }
        return self.factory.makeClipItemPreviewViewController(clipId: self.presenter.clip.identity, itemId: self.presenter.clip.items[index].identity)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let viewController = self.currentViewController else { return }

        self.tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
        viewController.previewView.delegate = self
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = self.resolveIndex(of: viewController), currentIndex > 0 else { return nil }
        return self.makeViewController(at: currentIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = self.resolveIndex(of: viewController), currentIndex < self.presenter.clip.items.count else { return nil }
        return self.makeViewController(at: currentIndex + 1)
    }
}

extension ClipPreviewPageViewController: UIGestureRecognizerDelegate {
    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer, gestureRecognizer === self.panGestureRecognizer {
            guard self.currentViewController?.previewView.isMinimumZoomScale == true else { return false }
            if gestureRecognizer.velocity(in: self.view).y > 0 {
                self.destination = .back
            } else {
                self.destination = .information
            }
            return true
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.currentViewController?.previewView.panGestureRecognizer {
            if self.currentViewController?.previewView.contentOffset.y == 0 {
                return true
            }
        }
        return false
    }
}

extension ClipPreviewPageViewController: ClipPreviewPageViewProtocol {
    // MARK: - ClipPreviewPageViewProtocol

    func reloadPages() {
        if let viewController = self.makeViewController(at: 0) {
            self.setViewControllers([viewController], direction: .forward, animated: true, completion: { [weak self] completed in
                guard let self = self, completed, let viewController = self.currentViewController else { return }

                self.tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
                viewController.previewView.delegate = self
            })
        }
        self.barItemsProvider.onUpdateClip()
    }

    func closePages() {
        self.previewTransitioningController.beginTransition(.custom(interactive: false))
        self.dismiss(animated: true, completion: nil)
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ClipPreviewPageViewController: ClipTargetFinderDelegate {
    // MARK: - ClipTargetCollectionViewControllerDelegate

    func didFinish(_ viewController: ClipTargetFinderViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didCancel(_ viewController: ClipTargetFinderViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension ClipPreviewPageViewController: ClipPreviewPageViewDelegate {
    // MARK: - ClipPreviewPageViewDelegate

    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewView) {
        self.isFullscreen = true
    }
}

extension ClipPreviewPageViewController: ClipInformationViewDataSource {
    // MARK: - ClipInformationViewDataSource

    func previewImage(_ view: ClipInformationView) -> UIImage? {
        guard let pageView = self.currentViewController?.previewView else { return nil }
        return pageView.image
    }

    func previewPageBounds(_ view: ClipInformationView) -> CGRect {
        guard let pageView = self.currentViewController?.previewView else { return .zero }
        return pageView.bounds
    }
}

extension ClipPreviewPageViewController: ClipItemPreviewAlertPresentable {}

extension ClipPreviewPageViewController: ClipPreviewPageBarButtonItemsProviderDelegate {
    // MARK: - ClipPreviewPageBarButtonItemsProviderDelegate

    func clipItemPreviewToolBarItemsProvider(_ provider: ClipPreviewPageBarButtonItemsProvider, shouldSetToolBarItems items: [UIBarButtonItem]) {
        self.setToolbarItems(items, animated: true)
    }

    func clipItemPreviewToolBarItemsProvider(_ provider: ClipPreviewPageBarButtonItemsProvider, shouldSetLeftBarButtonItems items: [UIBarButtonItem]) {
        self.navigationItem.leftBarButtonItems = items
    }

    func clipItemPreviewToolBarItemsProvider(_ provider: ClipPreviewPageBarButtonItemsProvider, shouldSetRightBarButtonItems items: [UIBarButtonItem]) {
        self.navigationItem.rightBarButtonItems = items
    }

    func shouldHideToolBar(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    func shouldShowToolBar(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        self.navigationController?.setToolbarHidden(false, animated: false)
    }

    func shouldDeleteClip(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        self.presenter.deleteClip()
    }

    func shouldDeleteClipImage(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        guard let clipId = self.currentViewController?.itemId else { return }
        self.presenter.removeClipItem(having: clipId)
    }

    func shouldAddToAlbum(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        let tags = self.presenter.clip.tags.map { $0.identity }
        let nullableViewController = self.factory.makeTagSelectionViewController(selectedTags: tags, context: nil, delegate: self)
        guard let viewController = nullableViewController else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldRefetchClip(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        guard let clipUrl = self.presenter.clip.url else { return }
        let viewController = self.factory.makeClipTargetCollectionViewController(clipUrl: clipUrl, delegate: self, isOverwrite: true)
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldOpenWeb(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        guard let clipUrl = self.presenter.clip.url else { return }
        UIApplication.shared.open(clipUrl, options: [:], completionHandler: nil)
    }

    func shouldBack(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        self.previewTransitioningController.beginTransition(.custom(interactive: false))
        self.dismiss(animated: true, completion: nil)
    }

    func shouldPresentInfo(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        guard let index = self.currentIndex, self.presenter.clip.items.indices.contains(index) else { return }
        let nullableViewController = self.factory.makeClipInformationViewController(
            clipId: self.presenter.clip.identity,
            itemId: self.presenter.clip.items[index].identity,
            transitioningController: self.informationTransitioningController,
            dataSource: self
        )
        guard let viewController = nullableViewController else { return }
        self.informationTransitioningController.beginTransition(.custom(interactive: false))
        self.present(viewController, animated: true, completion: nil)
    }
}

extension ClipPreviewPageViewController: AlbumSelectionPresenterDelegate {
    // MARK: - AlbumSelectionPresenterDelegate

    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?) {
        self.presenter.addClipToAlbum(albumId)
    }
}

extension ClipPreviewPageViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?) {
        self.presenter.addTagsToClip(tagIds)
    }
}
