//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol SettingsViewProtocol: AnyObject {
    func set(version: String)
}

class SettingsPresenter {
    private let storage: UserSettingsStorageProtocol
    private let container: CoreDataStackContainer
    private var cancellableBag: Set<AnyCancellable> = .init()

    private(set) var shouldShowHiddenItems: CurrentValueSubject<Bool, Never>
    private(set) var shouldSyncICloudEnabled: CurrentValueSubject<Bool, Never>

    weak var view: SettingsViewProtocol?

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol,
         container: CoreDataStackContainer)
    {
        self.storage = storage
        self.container = container
        self.shouldShowHiddenItems = .init(false)
        self.shouldSyncICloudEnabled = .init(false)

        self.storage.showHiddenItems
            .sink(receiveValue: { [weak self] value in
                self?.shouldShowHiddenItems.send(value)
            })
            .store(in: &self.cancellableBag)

        self.storage.enabledICloudSync
            .sink(receiveValue: { [weak self] value in
                self?.shouldSyncICloudEnabled.send(value)
            })
            .store(in: &self.cancellableBag)
    }

    func set(showHiddenItems: Bool) {
        self.storage.set(showHiddenItems: showHiddenItems)
    }

    func set(isICloudSyncEnabled: Bool) {
        self.storage.set(enabledICloudSync: isICloudSyncEnabled)
    }

    func displayVersion() {
        // swiftlint:disable:next force_cast force_unwrapping
        let versionString = Bundle(for: Self.self).infoDictionary!["CFBundleShortVersionString"] as! String
        self.view?.set(version: "\(versionString)")
    }
}
