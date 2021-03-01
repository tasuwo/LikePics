//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import TBoxCore
import TBoxUIKit
import UIKit

class ClipPreviewPageViewController: UIPageViewController {
    typealias Factory = ViewControllerFactory
    typealias Dependency = ClipPreviewPageViewModelType
    typealias TransitionControllerBuilder = (ClipInformationViewControllerFactory, UIViewController) -> ClipPreviewPageTransitionController

    private let factory: Factory
    private let viewModel: Dependency
    private let barItemsProvider: ClipPreviewPageBarViewController
    private let preLoadViewController: PreLoadingClipInformationViewController

    private var transitionController: ClipPreviewPageTransitionControllerType!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    private var isInitialLoaded: Bool = false

    private var isFullscreen = false {
        didSet {
            self.setNeedsStatusBarAppearanceUpdate()

            UIView.animate(withDuration: 0.2) {
                self.navigationController?.toolbar.isHidden = self.isFullscreen
                self.navigationController?.navigationBar.isHidden = self.isFullscreen
                self.parent?.view.backgroundColor = self.isFullscreen ? .black : Asset.Color.backgroundClient.color
            }
        }
    }

    private var currentPreviewSubscriptions: Set<AnyCancellable> = .init()
    private var subscriptions: Set<AnyCancellable> = .init()

    override var prefersStatusBarHidden: Bool {
        return self.isFullscreen
    }

    var currentItemId: ClipItem.Identity { viewModel.outputs.currentItemIdValue }

    var currentViewController: ClipPreviewViewController? {
        return self.viewControllers?.first as? ClipPreviewViewController
    }

    // MARK: - Lifecycle

    init(factory: Factory,
         viewModel: Dependency,
         preLoadViewController: PreLoadingClipInformationViewController,
         barItemsProvider: ClipPreviewPageBarViewController,
         transitionControllerBuilder: @escaping TransitionControllerBuilder)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.barItemsProvider = barItemsProvider
        self.preLoadViewController = preLoadViewController

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 40
        ])

        self.transitionController = transitionControllerBuilder(self, self)

        preLoadViewController.currentPageViewControllerProvider = { [weak self] in
            self?.currentViewController
        }

        self.addChild(barItemsProvider)
        self.addChild(preLoadViewController)
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
        self.setupAccessibilityIdentifiers()
        self.setupBar()
        self.setupPreLoadView()
        self.setupGestureRecognizer()

        self.bind(to: viewModel)

        guard let viewController = factory.makeClipPreviewViewController(itemId: viewModel.outputs.currentItemIdValue,
                                                                         usesImageForPresentingAnimation: true) else { return }
        self.setViewControllers([viewController], direction: .forward, animated: false)

        preLoadViewController.pageViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !self.isInitialLoaded, let viewController = self.currentViewController {
            self.didChangedCurrentPage(to: viewController)
            self.isInitialLoaded = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        preLoadViewController.pageViewWillDisappear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        preLoadViewController.pageViewDidAppear()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.navigationItem.title = ""
        self.modalTransitionStyle = .crossDissolve
    }

    private func setupAccessibilityIdentifiers() {
        self.navigationController?.navigationBar.accessibilityIdentifier = "\(String(describing: Self.self)).navigationBar"
    }

    private func setupPreLoadView() {
        view.insertSubview(preLoadViewController.view, at: 0)
        preLoadViewController.view.backgroundColor = .clear
        NSLayoutConstraint.activate(preLoadViewController.view.constraints(fittingIn: view))
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.displayErrorMessage
            .sink { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.reloadCurrentPage
            .sink { [weak self] in
                guard let currentViewController = self?.currentViewController else { return }
                self?.setViewControllers([currentViewController], direction: .forward, animated: false, completion: nil)
            }
            .store(in: &self.subscriptions)

        dependency.outputs.loadPage
            .sink { [weak self] itemId in
                guard let viewController = self?.factory.makeClipPreviewViewController(itemId: itemId, usesImageForPresentingAnimation: false) else { return }
                self?.setViewControllers([viewController], direction: .forward, animated: false) { completed in
                    guard completed else { return }
                    self?.didChangedCurrentPage(to: viewController, forced: true)
                }
            }
            .store(in: &self.subscriptions)

        dependency.outputs.close
            .sink { [weak self] _ in self?.transitionController.inputs.beginDismissal.send(()) }
            .store(in: &self.subscriptions)

        self.barItemsProvider.bind(view: self, viewModel: dependency)
    }

    private func didChangedCurrentPage(to viewController: ClipPreviewViewController, forced: Bool = false) {
        self.preLoadViewController.pageViewDidChangedCurrentPage(to: viewController)

        self.tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
        viewController.previewView.delegate = self

        self.currentPreviewSubscriptions.forEach { $0.cancel() }
        viewController.previewView.isMinimumZoomScale
            .sink { [weak self] isMinimumZoomScale in
                self?.transitionController.inputs.isMinimumPreviewZoomScale.send(isMinimumZoomScale)
            }
            .store(in: &self.currentPreviewSubscriptions)
        viewController.previewView.contentOffset
            .sink { [weak self] offset in
                self?.transitionController.inputs.previewContentOffset.send(offset)
            }
            .store(in: &self.currentPreviewSubscriptions)
        self.transitionController.inputs.previewPanGestureRecognizer.send(viewController.previewView.panGestureRecognizer)

        if !forced {
            self.viewModel.inputs.pageChanged.send(viewController.itemId)
        }
    }

    // MARK: Bar

    private func setupBar() {
        self.barItemsProvider.alertPresentable = self
        self.barItemsProvider.delegate = self
    }

    // MARK: Gesture Recognizer

    private func setupGestureRecognizer() {
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        self.tapGestureRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }

    @objc
    func didTap(_ sender: UITapGestureRecognizer) {
        self.isFullscreen = !self.isFullscreen
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let viewController = self.currentViewController else { return }
        self.didChangedCurrentPage(to: viewController)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let itemId = viewModel.outputs.itemId(before: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(itemId: itemId, usesImageForPresentingAnimation: false)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = viewController as? ClipPreviewViewController else { return nil }
        guard let itemId = viewModel.outputs.itemId(after: viewController.itemId) else { return nil }
        return factory.makeClipPreviewViewController(itemId: itemId, usesImageForPresentingAnimation: false)
    }
}

extension ClipPreviewPageViewController: ClipCreationDelegate {
    // MARK: - ClipTargetCollectionViewControllerDelegate

    func didFinish(_ viewController: ClipCreationViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }

    func didCancel(_ viewController: ClipCreationViewController) {
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
        return self.currentViewController?.previewView.image
    }

    func previewPageBounds(_ view: ClipInformationView) -> CGRect {
        return self.currentViewController?.previewView?.bounds ?? .zero
    }
}

extension ClipPreviewPageViewController: ClipPreviewAlertPresentable {}

extension ClipPreviewPageViewController: ClipPreviewPageBarButtonItemsProviderDelegate {
    // MARK: - ClipPreviewPageBarButtonItemsProviderDelegate

    func shouldDeleteClip(_ provider: ClipPreviewPageBarViewController) {
        self.viewModel.inputs.deleteClip.send(())
    }

    func shouldDeleteClipImage(_ provider: ClipPreviewPageBarViewController) {
        guard let clipId = self.currentViewController?.itemId else { return }
        self.viewModel.inputs.removeItem.send(clipId)
    }

    func shouldAddToAlbum(_ provider: ClipPreviewPageBarViewController) {
        // TODO:
        // guard let viewController = self.factory.makeAlbumSelectionViewController(context: nil, delegate: self) else { return }
        // self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipPreviewPageBarViewController) {
        // TODO:
        // let tagIds = viewModel.outputs.tagIdsValue
        // let nullableViewController = self.factory.makeTagSelectionViewController(selectedTags: tagIds, context: nil, delegate: self)
        // guard let viewController = nullableViewController else { return }
        // self.present(viewController, animated: true, completion: nil)
    }

    func shouldOpenWeb(_ provider: ClipPreviewPageBarViewController) {
        guard let url = self.currentViewController?.itemUrl else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func shouldBack(_ provider: ClipPreviewPageBarViewController) {
        self.transitionController.inputs.beginDismissal.send(())
    }

    func shouldPresentInfo(_ provider: ClipPreviewPageBarViewController) {
        self.transitionController.inputs.beginPresentInformation.send(())
    }

    func fetchImage(_ provider: ClipPreviewPageBarViewController) -> Data? {
        return self.viewModel.outputs.fetchImage()
    }

    func fetchImages(_ provider: ClipPreviewPageBarViewController) -> [Data] {
        return self.viewModel.outputs.fetchImagesInClip()
    }

    func present(_ provider: ClipPreviewPageBarViewController, controller: UIActivityViewController) {
        self.present(controller, animated: true, completion: nil)
    }
}

/*
 extension ClipPreviewPageViewController: AlbumSelectionPresenterDelegate {
     // MARK: - AlbumSelectionPresenterDelegate

     func albumSelectionPresenter(_ presenter: AlbumSelectionViewModel, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?) {
         self.viewModel.inputs.addToAlbum.send(albumId)
     }
 }

 extension ClipPreviewPageViewController: TagSelectionDelegate {
     // MARK: - TagSelectionPresenterDelegate

     func tagSelection(_ sender: AnyObject, didSelectTags tags: [Tag], withContext context: Any?) {
         let tagIds = Set(tags.map { $0.id })
         self.viewModel.inputs.replaceTags.send(tagIds)
     }
 }
  */

extension ClipPreviewPageViewController: ClipPreviewPageViewProtocol {}

extension ClipPreviewPageViewController: ClipInformationViewControllerFactory {
    // MARK: - ClipInformationViewControllerFactory

    func make(transitioningController: ClipInformationTransitioningControllerProtocol) -> UIViewController? {
        return self.factory.makeClipInformationViewController(
            clipId: self.viewModel.outputs.clipId,
            itemId: viewModel.outputs.currentItemIdValue,
            informationView: preLoadViewController.preLoadingInformationView,
            transitioningController: transitioningController,
            dataSource: self
        )
    }
}
