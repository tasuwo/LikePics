//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SettingsViewProtocol: AnyObject {}

class SettingsPresenter {
    private let storage: UserSettingsStorageProtocol

    var shouldShowHiddenItems: Bool {
        get {
            self.storage.fetch().showHiddenItems
        }
        set {
            self.storage.set(showHiddenItems: newValue)
        }
    }

    weak var view: SettingsViewProtocol?

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol) {
        self.storage = storage
    }
}
