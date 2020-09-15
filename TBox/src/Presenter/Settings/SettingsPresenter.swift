//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol SettingsViewProtocol: AnyObject {}

class SettingsPresenter {
    private let storage: UserSettingStorageProtocol

    var shouldShowHiddenItems: Bool {
        get {
            self.storage.fetchShowHiddenItems()
        }
        set {
            self.storage.set(showHiddenItems: newValue)
        }
    }

    weak var view: SettingsViewProtocol?

    // MARK: - Lifecycle

    init(storage: UserSettingStorageProtocol) {
        self.storage = storage
    }
}
