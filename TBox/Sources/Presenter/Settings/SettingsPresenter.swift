//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol SettingsViewProtocol: AnyObject {
    func set(version: String)
    func showICloudUnavailableMessage()
}

class SettingsPresenter {
    private let storage: UserSettingsStorageProtocol
    private let availabilityStore: CloudAvailabilityStore

    private var cancellableBag: Set<AnyCancellable> = .init()

    private(set) var shouldShowHiddenItems: CurrentValueSubject<Bool, Never>
    private(set) var shouldSyncICloudEnabled: CurrentValueSubject<Bool, Never>

    weak var view: SettingsViewProtocol?

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol,
         availabilityStore: CloudAvailabilityStore)
    {
        self.storage = storage
        self.availabilityStore = availabilityStore
        self.shouldShowHiddenItems = .init(false)
        self.shouldSyncICloudEnabled = .init(false)

        self.storage.showHiddenItems
            .sink(receiveValue: { [weak self] value in
                self?.shouldShowHiddenItems.send(value)
            })
            .store(in: &self.cancellableBag)

        self.storage.enabledICloudSync
            .combineLatest(self.availabilityStore.state)
            .sink(receiveValue: { [weak self] settingEnabled, availability in
                let isOn = settingEnabled && availability.isAvailable
                self?.shouldSyncICloudEnabled.send(isOn)
            })
            .store(in: &self.cancellableBag)
    }

    func set(showHiddenItems: Bool) {
        self.storage.set(showHiddenItems: showHiddenItems)
    }

    func set(isICloudSyncEnabled: Bool) -> Bool {
        switch self.availabilityStore.state.value {
        case .available:
            // TODO: 同期のオン/オフ時に必要に応じてユーザ向け案内文言を表示する
            self.storage.set(enabledICloudSync: isICloudSyncEnabled)
            return true

        default:
            self.view?.showICloudUnavailableMessage()
            return false
        }
    }

    func displayVersion() {
        // swiftlint:disable:next force_cast force_unwrapping
        let versionString = Bundle(for: Self.self).infoDictionary!["CFBundleShortVersionString"] as! String
        self.view?.set(version: "\(versionString)")
    }
}
