//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxCore
import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipPreviewPagePresenter
    private let transitionController: ClipPreviewTransitionControllerProtocol

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecignizer: UITapGestureRecognizer!

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

    init(factory: Factory, presenter: ClipPreviewPagePresenter, transitionController: ClipPreviewTransitionControllerProtocol) {
        self.factory = factory
        self.presenter = presenter
        self.transitionController = transitionController
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

        self.setupNavigationBar()
        self.setupToolBar()
        self.setupGestureRecognizer()

        self.presenter.reload()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        self.updateNavigationBar()
        self.updateToolbarAppearance()
    }

    // MARK: - Methods

    // MARK: Navigation Bar

    private func setupNavigationBar() {
        self.navigationItem.title = ""

        self.navigationItem.leftBarButtonItem = .init(title: "Back", style: .plain, target: self, action: #selector(self.didTapBack))

        self.updateNavigationBar()
    }

    private func updateNavigationBar() {
        let rightBarButtonItems: [UIBarButtonItem]
        if UIDevice.current.orientation.isLandscape {
            let reloadItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.didTapRefetch))
            let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapRemove))
            rightBarButtonItems = [removeItem, reloadItem]
        } else {
            rightBarButtonItems = []
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
    }

    @objc func didTapBack() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: Tool Bar

    private func setupToolBar() {
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let reloadItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.didTapRefetch))
        let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapRemove))
        let openWebItem = UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(self.didTapOpenWeb))
        let addToAlbumItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.didTapAddToAlbum))

        self.setToolbarItems([reloadItem, flexibleItem, openWebItem, flexibleItem, addToAlbumItem, flexibleItem, removeItem], animated: false)

        self.updateToolbarAppearance()
    }

    private func updateToolbarAppearance() {
        self.navigationController?.setToolbarHidden(UIDevice.current.orientation.isLandscape, animated: false)
    }

    @objc private func didTapRemove() {
        self.currentViewController?.didTapRemove()
    }

    @objc private func didTapRefetch() {
        let viewController = self.factory.makeClipTargetCollectionViewController(clipUrl: self.presenter.clip.url, delegate: self, isOverwrite: true)
        self.present(viewController, animated: true, completion: nil)
    }

    @objc private func didTapOpenWeb() {
        UIApplication.shared.open(self.presenter.clip.url, options: [:], completionHandler: nil)
    }

    @objc private func didTapAddToAlbum() {
        let viewController = self.factory.makeAddingClipsToAlbumViewController(clips: [self.presenter.clip], delegate: nil)
        self.present(viewController, animated: true, completion: nil)
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.panGestureRecognizer)

        self.tapGestureRecignizer = UITapGestureRecognizer(target: self, action: #selector(self.didtap(_:)))
        self.tapGestureRecignizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(self.tapGestureRecignizer)
    }

    @objc func didPan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            self.currentViewController?.pageView.isScrollEnabled = false
            self.transitionController.beginInteractiveTransition()
            self.dismiss(animated: true, completion: nil)
        case .ended:
            if self.transitionController.isInteractiveTransitioning {
                self.currentViewController?.pageView.isScrollEnabled = true
                self.transitionController.endInteractiveTransition()
                self.transitionController.didPan(sender: sender)
            }
        default:
            if self.transitionController.isInteractiveTransitioning {
                self.transitionController.didPan(sender: sender)
            }
        }
    }

    @objc func didtap(_ sender: UITapGestureRecognizer) {
        self.isFullscreen = !self.isFullscreen
    }

    // MARK: Page resolution

    private func resolveIndex(of viewController: UIViewController) -> Int? {
        guard let viewController = viewController as? ClipItemPreviewViewController else { return nil }
        guard let currentIndex = self.presenter.clip.items.firstIndex(where: { $0 == viewController.clipItem }) else { return nil }
        return currentIndex
    }

    private func makeViewController(at index: Int) -> UIViewController? {
        guard self.presenter.clip.items.indices.contains(index) else { return nil }
        return self.factory.makeClipItemPreviewViewController(clip: self.presenter.clip,
                                                              item: self.presenter.clip.items[index],
                                                              delegate: self)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let viewController = self.currentViewController else { return }

        self.tapGestureRecignizer.require(toFail: viewController.pageView.zoomGestureRecognizer)
        viewController.pageView.delegate = self
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
            return gestureRecognizer.velocity(in: self.view).y > 0
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.currentViewController?.pageView.panGestureRecognizer {
            if self.currentViewController?.pageView.contentOffset.y == 0 {
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

                self.tapGestureRecignizer.require(toFail: viewController.pageView.zoomGestureRecognizer)
                viewController.pageView.delegate = self
            })
        }
    }

    func showErrorMessage(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ClipPreviewPageViewController: ClipItemPreviewViewControllerDelegate {
    // MARK: - ClipItemPreviewViewControllerDelegate

    func reloadPages(_ viewController: ClipItemPreviewViewController) {
        self.presenter.reload()
    }
}

extension ClipPreviewPageViewController: ClipTargetFinderDelegate {
    // MARK: - ClipTargetCollectionViewControllerDelegate

    func didFinish(_ viewController: ClipTargetFinderViewController) {
        viewController.dismiss(animated: true, completion: nil)
        self.presenter.reload()
    }

    func didCancel(_ viewController: ClipTargetFinderViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}

extension ClipPreviewPageViewController: ClipPreviewPageViewDelegate {
    // MARK: - ClipPreviewPageViewDelegate

    func clipPreviewPageViewWillBeginZoom(_ view: ClipPreviewPageView) {
        self.isFullscreen = true
    }
}
