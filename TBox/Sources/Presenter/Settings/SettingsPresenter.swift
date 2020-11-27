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
    private let container: CoreDataStackContainer
    private let availabilityStore: CloudAvailabilityStore
    private var cancellableBag: Set<AnyCancellable> = .init()

    private(set) var shouldShowHiddenItems: CurrentValueSubject<Bool, Never>
    private(set) var shouldSyncICloudEnabled: CurrentValueSubject<Bool, Never>

    weak var view: SettingsViewProtocol?

    // MARK: - Lifecycle

    init(storage: UserSettingsStorageProtocol,
         container: CoreDataStackContainer,
         availabilityStore: CloudAvailabilityStore)
    {
        self.storage = storage
        self.container = container
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
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] isICloudSyncEnabled, cloudAvailability in
                let enabled = isICloudSyncEnabled && cloudAvailability == .available
                self?.shouldSyncICloudEnabled.send(enabled)
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
            self.container.reloadStack(isICloudSyncEnabled: isICloudSyncEnabled)
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
