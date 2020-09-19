//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipsListToolBarItemsProviderDelegate: AnyObject {
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
    weak var delegate: ClipsListToolBarItemsProviderDelegate?

    // TODO: protocol を切る
    weak var viewController: UIViewController? {
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
        self.viewController?.navigationController?.setToolbarHidden(!editing, animated: animated)
        self.presenter.setEditing(editing, animated: animated)
    }

    // MARK: Privates

    @objc
    private func didTapAddToAlbum() {
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
    private func didTapRemove() {
        self.alertPresentable?.presentRemoveAlert(targetCount: self.presenter.actionTargetCount) { [weak self] in
            guard let self = self else { return }
            self.delegate?.shouldDelete(self)
        }
    }

    @objc
    private func didTapRemoveFromAlbum() {
        self.alertPresentable?.presentRemoveFromAlbumAlert(
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
    private func didTapHide() {
        self.alertPresentable?.presentHideAlert(targetCount: self.presenter.actionTargetCount) { [weak self] in
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

    func set(_ items: [ClipsListToolBarItemsPresenter.Item]) {
        self.viewController?.setToolbarItems(items.map { self.resolveBarButtonItem(for: $0) }, animated: true)
    }
}
