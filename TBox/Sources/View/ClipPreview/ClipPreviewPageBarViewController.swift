//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import UIKit

protocol ClipPreviewPageViewProtocol: AnyObject {
    var navigationItem: UINavigationItem { get }
    var navigationController: UINavigationController? { get }
    func setToolbarItems(_ toolbarItems: [UIBarButtonItem]?, animated: Bool)
}

protocol ClipPreviewPageBarButtonItemsProviderDelegate: AnyObject {
    func shouldDeleteClip(_ provider: ClipPreviewPageBarViewController)
    func shouldDeleteClipImage(_ provider: ClipPreviewPageBarViewController)
    func shouldAddToAlbum(_ provider: ClipPreviewPageBarViewController)
    func shouldAddTags(_ provider: ClipPreviewPageBarViewController)
    func shouldOpenWeb(_ provider: ClipPreviewPageBarViewController)
    func shouldBack(_ provider: ClipPreviewPageBarViewController)
    func shouldPresentInfo(_ provider: ClipPreviewPageBarViewController)

    func fetchImage(_ provider: ClipPreviewPageBarViewController) -> Data?
    func fetchImages(_ provider: ClipPreviewPageBarViewController) -> [Data]

    func present(_ provider: ClipPreviewPageBarViewController, controller: UIActivityViewController)
}

class ClipPreviewPageBarViewController: UIViewController {
    typealias Dependency = ClipPreviewPageBarViewModelType

    private lazy var flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                                    target: nil,
                                                    action: nil)
    private lazy var deleteClipItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                                      target: self,
                                                      action: #selector(self.didTapDeleteClip))
    private lazy var deleteOnlyImageOrClipImage = UIBarButtonItem(barButtonSystemItem: .trash,
                                                                  target: self,
                                                                  action: #selector(self.didTapDeleteOnlyImageOrClip))
    private lazy var openWebItem = UIBarButtonItem(image: UIImage(systemName: "globe"),
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(self.didTapOpenWeb))
    private lazy var addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                               target: self,
                                               action: #selector(self.didTapAdd))
    private lazy var backItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left",
                                                               withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)),
                                                style: .plain,
                                                target: self,
                                                action: #selector(self.didTapBack))
    private lazy var infoItem = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(self.didTapInfo))
    private lazy var shareItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(self.didTapShare))

    weak var alertPresentable: ClipItemPreviewAlertPresentable?
    weak var delegate: ClipPreviewPageBarButtonItemsProviderDelegate?

    private let viewModel: ClipPreviewPageBarViewModelType
    private var cancellableBag: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    init(viewModel: ClipPreviewPageBarViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        self.setupAccessibilityIdentifiers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.viewModel.inputs.isVerticalCompact.send(self.traitCollection.verticalSizeClass == .compact)
        }
    }

    // MARK: - Methods

    func bind(view: ClipPreviewPageViewProtocol, viewModel: ClipPreviewPageViewModelType) {
        self.bind(dependency: self.viewModel, view: view, viewModel: viewModel)
    }

    // MARK: Privates

    private func bind(dependency: Dependency, view: ClipPreviewPageViewProtocol, viewModel: ClipPreviewPageViewModelType) {
        // MARK: Inputs

        dependency.inputs.isVerticalCompact.send(self.traitCollection.verticalSizeClass == .compact)

        viewModel.outputs.currentItem
            .sink { dependency.inputs.currentClipItem.send($0) }
            .store(in: &self.cancellableBag)

        viewModel.outputs.items
            .map { $0.count }
            .sink { dependency.inputs.clipItemCount.send($0) }
            .store(in: &self.cancellableBag)

        // MARK: Outputs

        dependency.outputs.displayToolBar
            .sink { [weak view] display in view?.navigationController?.setToolbarHidden(!display, animated: false) }
            .store(in: &self.cancellableBag)

        dependency.outputs.leftItems
            .map { [weak self] items in
                self?.resolveBarButtonItems(for: items)
                    .reversed()
            }
            .sink { view.navigationItem.setLeftBarButtonItems($0, animated: true) }
            .store(in: &self.cancellableBag)

        dependency.outputs.rightItems
            .map { [weak self] items in
                self?.resolveBarButtonItems(for: items)
                    .reversed()
            }
            .sink { view.navigationItem.setRightBarButtonItems($0, animated: true) }
            .store(in: &self.cancellableBag)

        dependency.outputs.toolBarItems
            .map { [weak self] items in
                self?.resolveBarButtonItems(for: items)
            }
            .sink { [weak view] items in view?.setToolbarItems(items, animated: false) }
            .store(in: &self.cancellableBag)
    }

    @objc
    private func didTapDeleteClip(item: UIBarButtonItem) {
        self.alertPresentable?.presentDeleteAlert(
            at: item,
            deleteClipItemAction: nil,
            deleteClipAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldDeleteClip(self)
            }
        )
    }

    @objc
    private func didTapDeleteOnlyImageOrClip(item: UIBarButtonItem) {
        self.alertPresentable?.presentDeleteAlert(
            at: item,
            deleteClipItemAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldDeleteClipImage(self)
            },
            deleteClipAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldDeleteClip(self)
            }
        )
    }

    @objc
    private func didTapOpenWeb() {
        self.delegate?.shouldOpenWeb(self)
    }

    @objc
    private func didTapAdd(item: UIBarButtonItem) {
        self.alertPresentable?.presentAddAlert(
            at: item,
            addToAlbumAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldAddToAlbum(self)
            },
            addTagsAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldAddTags(self)
            }
        )
    }

    @objc
    private func didTapBack() {
        self.delegate?.shouldBack(self)
    }

    @objc
    private func didTapInfo() {
        self.delegate?.shouldPresentInfo(self)
    }

    @objc
    private func didTapShare(item: UIBarButtonItem) {
        let shareItemAction = { [weak self] in
            guard let self = self, let image = self.delegate?.fetchImage(self) else { return }
            let controller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            controller.popoverPresentationController?.barButtonItem = self.shareItem
            self.delegate?.present(self, controller: controller)
        }

        let shareItemsAction = { [weak self] in
            guard let self = self, let images = self.delegate?.fetchImages(self) else { return }
            let controller = UIActivityViewController(activityItems: images, applicationActivities: nil)
            controller.popoverPresentationController?.barButtonItem = self.shareItem
            self.delegate?.present(self, controller: controller)
        }

        let clipItemCount = self.viewModel.outputs.clipItemCount.value
        if clipItemCount > 1 {
            self.alertPresentable?.presentShareAlert(at: item,
                                                     targetCount: clipItemCount,
                                                     shareItemAction: shareItemAction,
                                                     shareItemsAction: shareItemsAction)
        } else {
            shareItemsAction()
        }
    }

    private func resolveBarButtonItems(for items: [ClipPreview.BarItem]) -> [UIBarButtonItem] {
        return items.reduce(into: [UIBarButtonItem]()) { array, item in
            if !array.isEmpty { array.append(self.flexibleItem) }
            array.append(self.resolveBarButtonItem(for: item))
        }
    }

    private func resolveBarButtonItem(for item: ClipPreview.BarItem) -> UIBarButtonItem {
        let buttonItem: UIBarButtonItem = {
            switch item.kind {
            case .add:
                return self.addItem

            case .deleteOnlyImageOrClip:
                return self.deleteOnlyImageOrClipImage

            case .deleteClip:
                return self.deleteClipItem

            case .openWeb:
                return self.openWebItem

            case .back:
                return self.backItem

            case .info:
                return self.infoItem

            case .share:
                return self.shareItem
            }
        }()
        buttonItem.isEnabled = item.isEnabled
        return buttonItem
    }

    private func setupAccessibilityIdentifiers() {
        self.deleteClipItem.accessibilityIdentifier = "\(String(describing: Self.self)).deleteClipItem"
        self.deleteOnlyImageOrClipImage.accessibilityIdentifier = "\(String(describing: Self.self)).deleteOnlyImageOrClipImage"
        self.openWebItem.accessibilityIdentifier = "\(String(describing: Self.self)).openWebItem"
        self.addItem.accessibilityIdentifier = "\(String(describing: Self.self)).addItem"
        self.backItem.accessibilityIdentifier = "\(String(describing: Self.self)).backItem"
        self.infoItem.accessibilityIdentifier = "\(String(describing: Self.self)).infoItem"
    }
}
