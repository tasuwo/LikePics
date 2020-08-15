//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias Factory = ViewControllerFactory

    private let factory: Factory
    private let presenter: ClipPreviewPagePresenter
    private let transitionController: ClipPreviewTransitionControllerProtocol

    private var panGestureRecognizer: UIPanGestureRecognizer!

    private var nextIndex: Int?
    private var currentIndex: Int = 0

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let viewController = self.makeViewController(at: 0) {
            self.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
        }

        self.dataSource = self

        self.setupNavigationBar()
        self.setupToolBar()
        self.setupGestureRecognizer()
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
        let reloadItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.didTapRefetch))
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(self.didTapRemove))

        self.setToolbarItems([reloadItem, flexibleItem, removeItem], animated: false)

        self.updateToolbarAppearance()
    }

    private func updateToolbarAppearance() {
        self.navigationController?.setToolbarHidden(UIDevice.current.orientation.isLandscape, animated: false)
    }

    @objc private func didTapRemove() {
        print(#function)
    }

    @objc private func didTapRefetch() {
        print(#function)
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        self.panGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.panGestureRecognizer)
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

    // MARK: Page resolution

    private func resolveIndex(of viewController: UIViewController) -> Int? {
        guard let viewController = viewController as? ClipItemPreviewViewController else { return nil }
        guard let currentIndex = self.presenter.clip.items.firstIndex(where: { $0 == viewController.clipItem }) else { return nil }
        return currentIndex
    }

    private func makeViewController(at index: Int) -> UIViewController? {
        guard self.presenter.clip.items.indices.contains(index) else { return nil }
        return self.factory.makeClipItemPreviewViewController(clip: self.presenter.clip, item: self.presenter.clip.items[index])
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextViewController = pendingViewControllers.first, let nextIndex = self.resolveIndex(of: nextViewController) else {
            fatalError("Unexpected view controller detected.")
        }
        self.nextIndex = nextIndex
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let nextIndex = self.nextIndex, completed {
            self.currentIndex = nextIndex
        }
        self.nextIndex = nil
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
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer,
            gestureRecognizer === self.panGestureRecognizer
        {
            let shouldBegin: Bool = {
                if UIDevice.current.orientation.isLandscape {
                    return gestureRecognizer.velocity(in: self.view).x > 0
                } else {
                    return gestureRecognizer.velocity(in: self.view).y > 0
                }
            }()
            return shouldBegin
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
