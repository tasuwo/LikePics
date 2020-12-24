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
    private let viewModel: ClipPreviewPageViewModelType
    private let barItemsProvider: ClipPreviewPageBarViewController
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var transitionController: ClipPreviewPageTransitionControllerType!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var tapGestureRecognizer: UITapGestureRecognizer!

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

    private var currentPreviewCancellableBag: Set<AnyCancellable> = .init()
    private var cancellableBag: Set<AnyCancellable> = .init()

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
         viewModel: ClipPreviewPageViewModel,
         barItemsProvider: ClipPreviewPageBarViewController,
         transitionControllerBuilder: @escaping TransitionControllerBuilder)
    {
        self.factory = factory
        self.viewModel = viewModel
        self.barItemsProvider = barItemsProvider

        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [
            UIPageViewController.OptionsKey.interPageSpacing: 40
        ])

        self.transitionController = transitionControllerBuilder(self, self)

        self.addChild(barItemsProvider)
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
        self.setupGestureRecognizer()

        self.bind(to: viewModel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let currentViewController = self.currentViewController {
            self.bind(forCurrentViewController: currentViewController)
        }
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.navigationItem.title = ""
        self.modalTransitionStyle = .crossDissolve
    }

    private func setupAccessibilityIdentifiers() {
        self.navigationController?.navigationBar.accessibilityIdentifier = "\(String(describing: Self.self)).navigationBar"
    }

    // MARK: Bind

    private func bind(to dependency: Dependency) {
        dependency.outputs.items
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let viewController = self.makeViewController(at: 0) {
                    self.setViewControllers([viewController], direction: .forward, animated: true, completion: { [weak self] completed in
                        guard let self = self, completed, let viewController = self.currentViewController else { return }

                        self.tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
                        viewController.previewView.delegate = self
                    })
                }
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.errorMessage
            .sink { [weak self] message in
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(.init(title: L10n.confirmAlertOk, style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            .store(in: &self.cancellableBag)

        dependency.outputs.close
            .sink { [weak self] _ in self?.transitionController.inputs.beginDismissal.send(()) }
            .store(in: &self.cancellableBag)

        self.barItemsProvider.bind(view: self, viewModel: dependency)
    }

    private func bind(forCurrentViewController viewController: ClipItemPreviewViewController) {
        self.currentPreviewCancellableBag.forEach { $0.cancel() }

        viewController.previewView.isMinimumZoomScale
            .sink { [weak self] isMinimumZoomScale in
                self?.transitionController.inputs.isMinimumPreviewZoomScale.send(isMinimumZoomScale)
            }
            .store(in: &self.currentPreviewCancellableBag)

        viewController.previewView.contentOffset
            .sink { [weak self] offset in
                self?.transitionController.inputs.previewContentOffset.send(offset)
            }
            .store(in: &self.currentPreviewCancellableBag)

        self.transitionController.inputs.previewPanGestureRecognizer.send(viewController.previewView.panGestureRecognizer)
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

    // MARK: Page resolution

    private func resolveIndex(of viewController: UIViewController) -> Int? {
        guard let viewController = viewController as? ClipItemPreviewViewController else { return nil }
        guard let currentIndex = self.viewModel.outputs.items.value.firstIndex(where: { $0.identity == viewController.itemId }) else { return nil }
        return currentIndex
    }

    private func makeViewController(at index: Int) -> UIViewController? {
        guard self.viewModel.outputs.items.value.indices.contains(index) else { return nil }
        return self.factory.makeClipItemPreviewViewController(clipId: self.viewModel.outputs.clipId,
                                                              itemId: self.viewModel.outputs.items.value[index].identity)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDelegate {
    // MARK: - UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let viewController = self.currentViewController else { return }

        self.tapGestureRecognizer.require(toFail: viewController.previewView.zoomGestureRecognizer)
        viewController.previewView.delegate = self
        self.bind(forCurrentViewController: viewController)
    }
}

extension ClipPreviewPageViewController: UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDataSource

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = self.resolveIndex(of: viewController), currentIndex > 0 else { return nil }
        return self.makeViewController(at: currentIndex - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = self.resolveIndex(of: viewController), currentIndex < self.viewModel.outputs.items.value.count else { return nil }
        return self.makeViewController(at: currentIndex + 1)
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

    func shouldDeleteClip(_ provider: ClipPreviewPageBarViewController) {
        self.viewModel.inputs.deleteClip.send(())
    }

    func shouldDeleteClipImage(_ provider: ClipPreviewPageBarViewController) {
        guard let clipId = self.currentViewController?.itemId else { return }
        self.viewModel.inputs.removeClipItem.send(clipId)
    }

    func shouldAddToAlbum(_ provider: ClipPreviewPageBarViewController) {
        guard let viewController = self.factory.makeAlbumSelectionViewController(context: nil, delegate: self) else { return }
        self.present(viewController, animated: true, completion: nil)
    }

    func shouldAddTags(_ provider: ClipPreviewPageBarViewController) {
        let tags = self.viewModel.outputs.tags.value.map { $0.identity }
        let nullableViewController = self.factory.makeTagSelectionViewController(selectedTags: tags, context: nil, delegate: self)
        guard let viewController = nullableViewController else { return }
        self.present(viewController, animated: true, completion: nil)
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
}

extension ClipPreviewPageViewController: AlbumSelectionPresenterDelegate {
    // MARK: - AlbumSelectionPresenterDelegate

    func albumSelectionPresenter(_ presenter: AlbumSelectionPresenter, didSelectAlbumHaving albumId: Album.Identity, withContext context: Any?) {
        self.viewModel.inputs.addToAlbum.send(albumId)
    }
}

extension ClipPreviewPageViewController: TagSelectionPresenterDelegate {
    // MARK: - TagSelectionPresenterDelegate

    func tagSelectionPresenter(_ presenter: TagSelectionPresenter, didSelectTagsHaving tagIds: Set<Tag.Identity>, withContext context: Any?) {
        self.viewModel.inputs.addTags.send(tagIds)
    }
}

extension ClipPreviewPageViewController: ClipPreviewPageViewProtocol {}

extension ClipPreviewPageViewController: ClipInformationViewControllerFactory {
    // MARK: - ClipInformationViewControllerFactory

    func make(transitioningController: ClipInformationTransitioningControllerProtocol) -> UIViewController? {
        guard let index = self.currentIndex, self.viewModel.outputs.items.value.indices.contains(index) else { return nil }
        return self.factory.makeClipInformationViewController(
            clipId: self.viewModel.outputs.clipId,
            itemId: self.viewModel.outputs.items.value[index].identity,
            transitioningController: transitioningController,
            dataSource: self
        )
    }
}
