//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol SettingsViewProtocol: AnyObject {
    func set(version: String)
    func set(isICloudSyncEnabled: Bool)
    func show(title: String, message: String)
    func confirmToTurnOffICloudSync(confirmation: @escaping (Bool) -> Void)
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
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.shouldShowHiddenItems.send(value)
            })
            .store(in: &self.cancellableBag)

        self.storage.enabledICloudSync
            .combineLatest(self.availabilityStore.state)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] settingEnabled, availability in
                // TODO: availability == nil の時にSwitchをローディング状態にする
                let isOn = settingEnabled && availability?.isAvailable == true
                self?.shouldSyncICloudEnabled.send(isOn)
            })
            .store(in: &self.cancellableBag)
    }

    func set(showHiddenItems: Bool) {
        self.storage.set(showHiddenItems: showHiddenItems)
    }

    func set(isICloudSyncEnabled: Bool) -> Bool {
        guard let availability = self.availabilityStore.state.value else { return false }

        if isICloudSyncEnabled, availability == .unavailable {
            self.view?.show(title: L10n.errorIcloudUnavailableTitle,
                            message: L10n.errorIcloudUnavailableMessage)
            return false
        }

        if isICloudSyncEnabled {
            self.storage.set(enabledICloudSync: true)
        } else {
            self.view?.confirmToTurnOffICloudSync { [weak self] isOk in
                guard isOk else {
                    self?.view?.set(isICloudSyncEnabled: true)
                    return
                }
                self?.storage.set(enabledICloudSync: false)
            }
        }

        return true
    }

    func displayVersion() {
        // swiftlint:disable:next force_cast force_unwrapping
        let versionString = Bundle(for: Self.self).infoDictionary!["CFBundleShortVersionString"] as! String
        self.view?.set(version: "\(versionString)")
    }
}
