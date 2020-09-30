//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

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
    private let previewTransitionController: ClipPreviewTransitionControllerProtocol
    private let informationTransitionController: ClipInformationTransitionControllerProtocol

    private var destination: TransitionDestination?

    // swiftlint:disable:next implicitly_unwrapped_optional
    private var panGestureRecognizer: UIPanGestureRecognizer!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var tapGestureRecognizer: UITapGestureRecognizer!

    private var isFullscreen = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()

            guard let navigationController = self.navigationController else { return }
            UIView.animate(withDuration: 0.1, animations: {
                navigationController.toolbar.alpha = self.isFullscreen ? 0 : 1
                navigationController.navigationBar.alpha = self.isFullscreen ? 0 : 1
            })
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
         previewTransitionController: ClipPreviewTransitionControllerProtocol,
         informationTransitionController: ClipInformationTransitioningController)
    {
        self.factory = factory
        self.presenter = presenter
        self.barItemsProvider = barItemsProvider
        self.previewTransitionController = previewTransitionController
        self.informationTransitionController = informationTransitionController

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
            self.previewTransitionController.beginInteractiveTransition()
            self.dismiss(animated: true, completion: nil)

        case (.ended, .back):
            if self.previewTransitionController.isInteractiveTransitioning {
                self.currentViewController?.previewView.isScrollEnabled = true
                self.previewTransitionController.endInteractiveTransition()
                self.previewTransitionController.didPan(sender: sender)
            }
            self.destination = nil

        case (_, .back):
            if self.previewTransitionController.isInteractiveTransitioning {
                self.previewTransitionController.didPan(sender: sender)
            }

        case (.began, .information):
            guard let index = self.currentIndex, self.presenter.clip.items.indices.contains(index) else { return }
            self.informationTransitionController.beginInteractiveTransition(.present)
            let viewController = self.factory.makeClipInformationViewController(clip: self.presenter.clip,
                                                                                item: self.presenter.clip.items[index],
                                                                                dataSource: self)
            self.present(viewController, animated: true, completion: nil)

        case (.ended, .information):
            if self.informationTransitionController.isInteractiveTransitioning {
                self.informationTransitionController.endInteractiveTransition()
                self.informationTransitionController.didPan(sender: sender)
            }
            self.destination = nil

        case (_, .information):
            if self.informationTransitionController.isInteractiveTransitioning {
                self.informationTransitionController.didPan(sender: sender)
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
        self.previewTransitionController.beginDeletionTransition()
        self.dismiss(animated: true, completion: { [weak self] in
            self?.previewTransitionController.endDeletionTransition()
        })
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
        self.presenter.deleteClipItem(having: clipId)
    }

    func shouldAddToAlbum(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: [self.presenter.clip], delegate: nil)
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        let viewController = self.factory.makeAddingTagToClipViewController(clips: [self.presenter.clip], delegate: nil)
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldRefetchClip(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        let viewController = self.factory.makeClipTargetCollectionViewController(clipUrl: self.presenter.clip.url,
                                                                                 delegate: self,
                                                                                 isOverwrite: true)
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldOpenWeb(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        UIApplication.shared.open(self.presenter.clip.url, options: [:], completionHandler: nil)
    }

    func shouldBack(_ provider: ClipPreviewPageBarButtonItemsProvider) {
        self.dismiss(animated: true, completion: nil)
    }
}
