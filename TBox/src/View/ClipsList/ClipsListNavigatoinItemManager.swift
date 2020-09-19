//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListNavigationItemManagerDelegate: AnyObject {
    func didTapEditButton(_ manager: ClipsListNavigationItemManager)
    func didTapCancelButton(_ manager: ClipsListNavigationItemManager)
    func didTapSelectAllButton(_ manager: ClipsListNavigationItemManager)
    func didTapDeselectAllButton(_ manager: ClipsListNavigationItemManager)
}

protocol ClipsListNavigationItemManagerDataSource: AnyObject {
    func clipsCount(_ manager: ClipsListNavigationItemManager) -> Int
    func selectedClipsCount(_ manager: ClipsListNavigationItemManager) -> Int
}

class ClipsListNavigationItemManager {
    private let cancelButton = RoundedButton()
    private let selectAllButton = RoundedButton()
    private let deselectAllButton = RoundedButton()
    private let selectButton = RoundedButton()

    private var isEditing: Bool = false {
        didSet {
            self.updateItems()
        }
    }

    weak var delegate: ClipsListNavigationItemManagerDelegate?
    weak var dataSource: ClipsListNavigationItemManagerDataSource?
    weak var navigationItem: UINavigationItem? {
        didSet {
            self.updateItems()
        }
    }

    // MARK: - Lifecycle

    init() {
        self.cancelButton.setTitle(L10n.confirmAlertCancel, for: .normal)
        self.cancelButton.addTarget(self, action: #selector(self.didTapCancel), for: .touchUpInside)

        self.selectAllButton.setTitle(L10n.clipsListRightBarItemForSelectAllTitle, for: .normal)
        self.selectAllButton.addTarget(self, action: #selector(self.didTapSelectAll), for: .touchUpInside)

        self.deselectAllButton.setTitle(L10n.clipsListRightBarItemForDeselectAllTitle, for: .normal)
        self.deselectAllButton.addTarget(self, action: #selector(self.didTapDeselectAll), for: .touchUpInside)

        self.selectButton.setTitle(L10n.clipsListRightBarItemForSelectTitle, for: .normal)
        self.selectButton.addTarget(self, action: #selector(self.didTapEdit), for: .touchUpInside)
    }

    // MARK: - Methods

    func setEditing(_ editing: Bool, animated: Bool) {
        self.isEditing = editing
    }

    func onUpdateSelection() {
        self.updateItems()
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

    private func updateItems() {
        let isSelectedAll: Bool = {
            guard let dataSource = self.dataSource else { return false }
            return dataSource.clipsCount(self) <= dataSource.selectedClipsCount(self)
        }()

        if self.isEditing {
            self.navigationItem?.rightBarButtonItems = [
                UIBarButtonItem(customView: self.cancelButton)
            ]
            self.navigationItem?.leftBarButtonItems = [
                UIBarButtonItem(customView: isSelectedAll ? self.deselectAllButton : self.selectAllButton)
            ]
        } else {
            self.navigationItem?.rightBarButtonItems = [
                UIBarButtonItem(customView: self.selectButton)
            ]
            self.navigationItem?.leftBarButtonItems = []
        }
    }
}
