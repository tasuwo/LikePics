//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipsListToolBarItemsProviderDelegate: AnyObject {
    func clipsListToolBarItemsProvider(_ provider: ClipsListToolBarItemsProvider, shouldSetToolBarItems items: [UIBarButtonItem])
    func shouldHideToolBar(_ provider: ClipsListToolBarItemsProvider)
    func shouldShowToolBar(_ provider: ClipsListToolBarItemsProvider)
    func shouldAddToAlbum(_ provider: ClipsListToolBarItemsProvider)
    func shouldAddTags(_ provider: ClipsListToolBarItemsProvider)
    func shouldDelete(_ provider: ClipsListToolBarItemsProvider)
    func shouldRemoveFromAlbum(_ provider: ClipsListToolBarItemsProvider)
    func shouldHide(_ provider: ClipsListToolBarItemsProvider)
    func shouldUnhide(_ provider: ClipsListToolBarItemsProvider)
}

class ClipsListToolBarItemsProvider {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var flexibleItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var addItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var removeItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var removeFromAlbum: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var hideItem: UIBarButtonItem!
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var unhideItem: UIBarButtonItem!

    weak var alertPresentable: ClipsListAlertPresentable?
    weak var delegate: ClipsListToolBarItemsProviderDelegate? {
        didSet {
            self.presenter.toolBar = self
        }
    }

    private let presenter: ClipsListToolBarItemsPresenter

    // MARK: - Lifecycle

    init(presenter: ClipsListToolBarItemsPresenter) {
        self.presenter = presenter

        self.flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil,
                                            action: nil)
        self.addItem = UIBarButtonItem(barButtonSystemItem: .add,
                                       target: self,
                                       action: #selector(self.didTapAddToAlbum))
        self.removeItem = UIBarButtonItem(barButtonSystemItem: .trash,
                                          target: self,
                                          action: #selector(self.didTapRemove))
        self.removeFromAlbum = UIBarButtonItem(barButtonSystemItem: .trash,
                                               target: self,
                                               action: #selector(self.didTapRemoveFromAlbum))
        self.hideItem = UIBarButtonItem(image: UIImage(systemName: "eye.slash"),
                                        style: .plain,
                                        target: self,
                                        action: #selector(self.didTapHide))
        self.unhideItem = UIBarButtonItem(image: UIImage(systemName: "eye"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(self.didTapUnhide))
    }

    // MARK: - Methods

    func setEditing(_ editing: Bool, animated: Bool) {
        self.presenter.setEditing(editing, animated: animated)
    }

    // MARK: Privates

    @objc
    private func didTapAddToAlbum(item: UIBarButtonItem) {
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
    private func didTapRemove(item: UIBarButtonItem) {
        self.alertPresentable?.presentRemoveAlert(at: item, targetCount: self.presenter.actionTargetCount) { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldDelete(self)
        }
    }

    @objc
    private func didTapRemoveFromAlbum(item: UIBarButtonItem) {
        self.alertPresentable?.presentRemoveFromAlbumAlert(
            at: item,
            targetCount: self.presenter.actionTargetCount,
            deleteAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldDelete(self)
            },
            removeFromAlbumAction: { [weak self] in
                guard let self = self else { return }
                self.delegate?.shouldRemoveFromAlbum(self)
            }
        )
    }

    @objc
    private func didTapHide(item: UIBarButtonItem) {
        self.alertPresentable?.presentHideAlert(at: item, targetCount: self.presenter.actionTargetCount) { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldHide(self)
        }
    }

    @objc
    private func didTapUnhide() {
        self.delegate?.shouldUnhide(self)
    }

    private func resolveBarButtonItem(for item: ClipsListToolBarItemsPresenter.Item) -> UIBarButtonItem {
        switch item {
        case .spacer:
            return self.flexibleItem

        case .add:
            return self.addItem

        case .delete:
            return self.removeItem

        case .removeFromAlbum:
            return self.removeFromAlbum

        case .hide:
            return self.hideItem

        case .unhide:
            return self.unhideItem
        }
    }
}

extension ClipsListToolBarItemsProvider: ClipsListToolBar {
    // MARK: - ClipsListToolBar

    func showToolBar() {
        self.delegate?.shouldShowToolBar(self)
    }

    func hideToolBar() {
        self.delegate?.shouldHideToolBar(self)
    }

    func set(_ items: [ClipsListToolBarItemsPresenter.Item]) {
        self.delegate?.clipsListToolBarItemsProvider(self, shouldSetToolBarItems: items.map { self.resolveBarButtonItem(for: $0) })
    }
}

extension ClipsListToolBarItemsProviderDelegate where Self: UIViewController {
    func clipsListToolBarItemsProvider(_ provider: ClipsListToolBarItemsProvider, shouldSetToolBarItems items: [UIBarButtonItem]) {
        self.setToolbarItems(items, animated: true)
    }

    func shouldHideToolBar(_ provider: ClipsListToolBarItemsProvider) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    func shouldShowToolBar(_ provider: ClipsListToolBarItemsProvider) {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
}
