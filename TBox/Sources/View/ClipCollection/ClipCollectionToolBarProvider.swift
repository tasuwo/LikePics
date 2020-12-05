//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipCollectionToolBarProviderDelegate: AnyObject {
    func clipCollectionToolBarProvider(_ provider: ClipCollectionToolBarProvider, shouldSetToolBarItems items: [UIBarButtonItem])
    func shouldHideToolBar(_ provider: ClipCollectionToolBarProvider)
    func shouldShowToolBar(_ provider: ClipCollectionToolBarProvider)
    func shouldAddToAlbum(_ provider: ClipCollectionToolBarProvider)
    func shouldAddTags(_ provider: ClipCollectionToolBarProvider)
    func shouldDelete(_ provider: ClipCollectionToolBarProvider)
    func shouldRemoveFromAlbum(_ provider: ClipCollectionToolBarProvider)
    func shouldHide(_ provider: ClipCollectionToolBarProvider)
    func shouldUnhide(_ provider: ClipCollectionToolBarProvider)
}

class ClipCollectionToolBarProvider {
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

    weak var alertPresentable: ClipCollectionAlertPresentable?
    weak var delegate: ClipCollectionToolBarProviderDelegate? {
        didSet {
            self.presenter.toolBar = self
        }
    }

    private let presenter: ClipCollectionToolBarPresenter

    // MARK: - Lifecycle

    init(presenter: ClipCollectionToolBarPresenter) {
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

    private func resolveBarButtonItem(for item: ClipCollection.ToolBarItem) -> UIBarButtonItem {
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

extension ClipCollectionToolBarProvider: ClipCollectionToolBar {
    // MARK: - ClipCollectionToolBar

    func showToolBar() {
        self.delegate?.shouldShowToolBar(self)
    }

    func hideToolBar() {
        self.delegate?.shouldHideToolBar(self)
    }

    func set(_ items: [ClipCollection.ToolBarItem]) {
        self.delegate?.clipCollectionToolBarProvider(self, shouldSetToolBarItems: items.map { self.resolveBarButtonItem(for: $0) })
    }
}

extension ClipCollectionToolBarProviderDelegate where Self: UIViewController {
    func clipCollectionToolBarProvider(_ provider: ClipCollectionToolBarProvider, shouldSetToolBarItems items: [UIBarButtonItem]) {
        self.setToolbarItems(items, animated: true)
    }

    func shouldHideToolBar(_ provider: ClipCollectionToolBarProvider) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    func shouldShowToolBar(_ provider: ClipCollectionToolBarProvider) {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
}
