//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol SettingsViewProtocol: AnyObject {
    func set(version: String)
    func set(isICloudSyncEnabled: Bool)
    func confirmToUnavailabilityICloudSync(shouldTurnOff: @escaping (Bool) -> Void)
    func confirmToUnavailabilityICloudSync(shouldTurnOn: @escaping (Bool) -> Void)
    func confirmToTurnOffICloudSync(confirmation: @escaping (Bool) -> Void)
}

class SettingsPresenter {
    private let storage: UserSettingsStorageProtocol
    private let cloudAvailabilityService: CloudAvailabilityServiceProtocol

    private var subscriptions: Set<AnyCancellable> = .init()

    private(set) var shouldHideHiddenItems: CurrentValueSubject<Bool, Never>
    private(set) var shouldSyncICloudEnabled: CurrentValueSubject<Bool, Never>

    weak var view: SettingsViewProtocol?

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol,
         cloudAvailabilityService: CloudAvailabilityServiceProtocol)
    {
        self.storage = storage
        self.cloudAvailabilityService = cloudAvailabilityService
        self.shouldHideHiddenItems = .init(false)
        self.shouldSyncICloudEnabled = .init(false)

        self.storage.showHiddenItems
            .receive(on: DispatchQueue.main)
            .map { !$0 }
            .sink(receiveValue: { [weak self] value in
                self?.shouldHideHiddenItems.send(value)
            })
            .store(in: &self.subscriptions)

        // TODO:
        // self.storage.enabledICloudSync
        //     .combineLatest(self.cloudAvailabilityService.availability)
        //     .receive(on: DispatchQueue.main)
        //     .sink(receiveValue: { [weak self] settingEnabled, availability in
        //         let isOn = settingEnabled && availability?.isAvailable == true
        //         self?.shouldSyncICloudEnabled.send(isOn)
        //     })
        //     .store(in: &self.subscriptions)
    }

    func set(hideHiddenItems: Bool) {
        self.storage.set(showHiddenItems: !hideHiddenItems)
    }

    func set(isICloudSyncEnabled: Bool) -> Bool {
        // TODO:
        /*
        guard let availability = self.cloudAvailabilityService.state.value else { return false }

        if isICloudSyncEnabled, availability == .unavailable {
            let isEnabledICloudSync = self.storage.readEnabledICloudSync()
            if isEnabledICloudSync {
                self.view?.confirmToUnavailabilityICloudSync(shouldTurnOff: { [weak self] shouldTurnOff in
                    guard shouldTurnOff else { return }
                    self?.view?.confirmToTurnOffICloudSync { isOk in
                        guard isOk else { return }
                        self?.storage.set(enabledICloudSync: false)
                    }
                })
            } else {
                self.view?.confirmToUnavailabilityICloudSync(shouldTurnOn: { [weak self] shouldTurnOn in
                    guard shouldTurnOn else { return }
                    self?.storage.set(enabledICloudSync: true)
                })
            }
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
         */

        return true
    }

    func displayVersion() {
        // swiftlint:disable:next force_cast force_unwrapping
        let versionString = Bundle(for: Self.self).infoDictionary!["CFBundleShortVersionString"] as! String
        self.view?.set(version: "\(versionString)")
    }
}
