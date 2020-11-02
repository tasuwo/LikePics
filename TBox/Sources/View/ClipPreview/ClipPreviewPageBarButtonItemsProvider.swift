//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipPreviewPageBarButtonItemsProviderDelegate: AnyObject {
    func clipItemPreviewToolBarItemsProvider(_ provider: ClipPreviewPageBarButtonItemsProvider, shouldSetLeftBarButtonItems items: [UIBarButtonItem])
    func clipItemPreviewToolBarItemsProvider(_ provider: ClipPreviewPageBarButtonItemsProvider, shouldSetRightBarButtonItems items: [UIBarButtonItem])
    func clipItemPreviewToolBarItemsProvider(_ provider: ClipPreviewPageBarButtonItemsProvider, shouldSetToolBarItems items: [UIBarButtonItem])
    func shouldHideToolBar(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldShowToolBar(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldDeleteClip(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldDeleteClipImage(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldAddToAlbum(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldAddTags(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldOpenWeb(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldBack(_ provider: ClipPreviewPageBarButtonItemsProvider)
    func shouldPresentInfo(_ provider: ClipPreviewPageBarButtonItemsProvider)
}

class ClipPreviewPageBarButtonItemsProvider {
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

    private let presenter: ClipPreviewPageBarButtonItemsPresenter

    weak var alertPresentable: ClipItemPreviewAlertPresentable?
    weak var delegate: ClipPreviewPageBarButtonItemsProviderDelegate? {
        didSet {
            self.presenter.set(navigationBar: self, toolBar: self)
        }
    }

    // MARK: - Lifecycle

    init(presenter: ClipPreviewPageBarButtonItemsPresenter) {
        self.presenter = presenter
        self.setupAccessibilityIdentifiers()
    }

    // MARK: - Methods

    func onUpdateClip() {
        self.presenter.onUpdateClip()
    }

    func onUpdateOrientation() {
        self.presenter.onUpdateOrientation()
    }

    // MARK: Privates

    @objc
    private func didTapDeleteClip() {
        self.alertPresentable?.presentDeleteAlert(
            deleteClipItemAction: nil,
            deleteClipAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldDeleteClip(self)
            }
        )
    }

    @objc
    private func didTapDeleteOnlyImageOrClip() {
        self.alertPresentable?.presentDeleteAlert(
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
    private func didTapAdd() {
        self.alertPresentable?.presentAddAlert(
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

    private func resolveBarButtonItem(for item: ClipPreviewPageBarButtonItemsPresenter.Item) -> UIBarButtonItem {
        switch item {
        case .spacer:
            return self.flexibleItem

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
        }
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

extension ClipPreviewPageBarButtonItemsProvider: ClipPreviewPageToolBar {
    // MARK: - ClipPreviewPageToolBar

    var isLandscape: Bool {
        return UIDevice.current.orientation.isLandscape
    }

    func hide() {
        self.delegate?.shouldHideToolBar(self)
    }

    func show() {
        self.delegate?.shouldShowToolBar(self)
    }

    func set(_ items: [ClipPreviewPageBarButtonItemsPresenter.Item]) {
        self.delegate?.clipItemPreviewToolBarItemsProvider(self, shouldSetToolBarItems: items.map { self.resolveBarButtonItem(for: $0) })
    }
}

extension ClipPreviewPageBarButtonItemsProvider: ClipPreviewPageNavigationBar {
    // MARK: - ClipPreviewPageToolBar

    func setRightBarItems(_ items: [ClipPreviewPageBarButtonItemsPresenter.Item]) {
        self.delegate?.clipItemPreviewToolBarItemsProvider(self, shouldSetRightBarButtonItems: items.map { self.resolveBarButtonItem(for: $0) })
    }

    func setLeftBarItems(_ items: [ClipPreviewPageBarButtonItemsPresenter.Item]) {
        self.delegate?.clipItemPreviewToolBarItemsProvider(self, shouldSetLeftBarButtonItems: items.map { self.resolveBarButtonItem(for: $0) })
    }
}
