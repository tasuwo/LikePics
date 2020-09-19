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
}

class ClipsListNavigationItemsProvider {
    private let cancelButton = RoundedButton()
    private let selectAllButton = RoundedButton()
    private let deselectAllButton = RoundedButton()
    private let selectButton = RoundedButton()

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

    func setEditing(_ editing: Bool, animated: Bool) {
        self.presenter.setEditing(editing, animated: animated)
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

    private func setupButtons() {
        self.cancelButton.setTitle(L10n.confirmAlertCancel, for: .normal)
        self.cancelButton.addTarget(self, action: #selector(self.didTapCancel), for: .touchUpInside)

        self.selectAllButton.setTitle(L10n.clipsListRightBarItemForSelectAllTitle, for: .normal)
        self.selectAllButton.addTarget(self, action: #selector(self.didTapSelectAll), for: .touchUpInside)

        self.deselectAllButton.setTitle(L10n.clipsListRightBarItemForDeselectAllTitle, for: .normal)
        self.deselectAllButton.addTarget(self, action: #selector(self.didTapDeselectAll), for: .touchUpInside)

        self.selectButton.setTitle(L10n.clipsListRightBarItemForSelectTitle, for: .normal)
        self.selectButton.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)
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
        }
    }
}

extension ClipsListNavigationItemsProvider: ClipsListNavigationBar {
    // MARK: - ClipsListNavigationBar

    func setRightBarButtonItems(_ items: [ClipsListNavigationItemsPresenter.Item]) {
        self.navigationItem?.rightBarButtonItems = items
            .map { UIBarButtonItem(customView: self.resolveCustomView(for: $0)) }
    }

    func setLeftBarButtonItems(_ items: [ClipsListNavigationItemsPresenter.Item]) {
        self.navigationItem?.leftBarButtonItems = items
            .map { UIBarButtonItem(customView: self.resolveCustomView(for: $0)) }
    }
}
