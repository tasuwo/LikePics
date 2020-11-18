//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListNavigationItemsProviderDelegate: AnyObject {
    func didTapEditButton(_ provider: ClipsListNavigationItemsProvider)
    func didTapCancelButton(_ provider: ClipsListNavigationItemsProvider)
    func didTapSelectAllButton(_ provider: ClipsListNavigationItemsProvider)
    func didTapDeselectAllButton(_ provider: ClipsListNavigationItemsProvider)
    func didTapReorderButton(_ provider: ClipsListNavigationItemsProvider)
    func didTapDoneButton(_ provider: ClipsListNavigationItemsProvider)
}

class ClipsListNavigationItemsProvider {
    private let cancelButton = RoundedButton()
    private let selectAllButton = RoundedButton()
    private let deselectAllButton = RoundedButton()
    private let selectButton = RoundedButton()
    private let reorderButton = RoundedButton()
    private let doneButton = RoundedButton()

    private let presenter: ClipsListNavigationItemsPresenter

    weak var delegate: ClipsListNavigationItemsProviderDelegate?
    weak var navigationItem: UINavigationItem? {
        didSet {
            self.presenter.navigationBar = self
        }
    }

    // MARK: - Lifecycle

    init(presenter: ClipsListNavigationItemsPresenter) {
        self.presenter = presenter
        self.setupButtons()
    }

    // MARK: - Methods

    func set(_ state: ClipsListNavigationItemsPresenter.State) {
        self.presenter.set(state)
    }

    func onUpdateSelection() {
        self.presenter.onUpdateSelection()
    }

    // MARK: Privates

    @objc
    private func didTapEdit(_ sender: UIButton) {
        self.delegate?.didTapEditButton(self)
    }

    @objc
    private func didTapCancel(_ sender: UIButton) {
        self.delegate?.didTapCancelButton(self)
    }

    @objc
    private func didTapSelectAll(_ sender: UIButton) {
        self.delegate?.didTapSelectAllButton(self)
    }

    @objc
    private func didTapDeselectAll(_ sender: UIButton) {
        self.delegate?.didTapDeselectAllButton(self)
    }

    @objc
    private func didTapReorder(_ sender: UIButton) {
        self.delegate?.didTapReorderButton(self)
    }

    @objc
    private func didTapDone(_ sender: UIButton) {
        self.delegate?.didTapDoneButton(self)
    }

    private func setupButtons() {
        self.cancelButton.setTitle(L10n.confirmAlertCancel, for: .normal)
        self.cancelButton.addTarget(self, action: #selector(self.didTapCancel), for: .touchUpInside)

        self.selectAllButton.setTitle(L10n.clipsListRightBarItemForSelectAllTitle, for: .normal)
        self.selectAllButton.addTarget(self, action: #selector(self.didTapSelectAll), for: .touchUpInside)

        self.deselectAllButton.setTitle(L10n.clipsListRightBarItemForDeselectAllTitle, for: .normal)
        self.deselectAllButton.addTarget(self, action: #selector(self.didTapDeselectAll), for: .touchUpInside)

        self.selectButton.setTitle(L10n.clipsListRightBarItemForSelectTitle, for: .normal)
        self.selectButton.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)

        self.reorderButton.setTitle(L10n.clipsListRightBarItemForReorder, for: .normal)
        self.reorderButton.addTarget(self, action: #selector(self.didTapReorder), for: .touchUpInside)

        self.doneButton.setTitle(L10n.clipsListRightBarItemForDone, for: .normal)
        self.doneButton.addTarget(self, action: #selector(self.didTapDone(_:)), for: .touchUpInside)
    }

    private func resolveCustomView(for item: ClipsListNavigationItemsPresenter.Item) -> UIView {
        switch item {
        case .cancel:
            return self.cancelButton

        case .selectAll:
            return self.selectAllButton

        case .deselectAll:
            return self.deselectAllButton

        case .select:
            return self.selectButton

        case .reorder:
            return self.reorderButton

        case .done:
            return self.doneButton
        }
    }
}

extension ClipsListNavigationItemsProvider: ClipsListNavigationBar {
    // MARK: - ClipsListNavigationBar

    func setRightBarButtonItems(_ items: [ClipsListNavigationItemsPresenter.Item]) {
        self.navigationItem?.rightBarButtonItems = items
            .map {
                let item = UIBarButtonItem(customView: self.resolveCustomView(for: $0))
                item.isEnabled = $0.isEnabled
                return item
            }
    }

    func setLeftBarButtonItems(_ items: [ClipsListNavigationItemsPresenter.Item]) {
        self.navigationItem?.leftBarButtonItems = items
            .map {
                let item = UIBarButtonItem(customView: self.resolveCustomView(for: $0))
                item.isEnabled = $0.isEnabled
                return item
            }
    }
}
