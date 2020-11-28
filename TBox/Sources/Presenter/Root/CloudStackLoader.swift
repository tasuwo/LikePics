//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

class CloudStackLoader {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityStore: CloudAvailabilityStore
    private let cloudStack: CloudStack
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.CloudStackLoader")

    private var cancellableBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(userSettingsStorage: UserSettingsStorageProtocol,
         cloudAvailabilityStore: CloudAvailabilityStore,
         cloudStack: CloudStack)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityStore = cloudAvailabilityStore
        self.cloudStack = cloudStack
    }

    // MARK: - Methods

    func startObserveCloudAvailability() {
        self.cloudAvailabilityStore.state
            .combineLatest(self.userSettingsStorage.enabledICloudSync)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] availability, isICloudSyncEnabled in
                self?.didUpdate(cloudAvailability: availability, userSettingEnabled: isICloudSyncEnabled)
            })
            .store(in: &self.cancellableBag)
    }

    func didUpdate(cloudAvailability: CloudAvailability, userSettingEnabled: Bool) {
        switch (userSettingEnabled, cloudAvailability) {
        case (true, .available(.none)):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)

        case (true, .available(.accountChanged)):
            // TODO: アラートを出す
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)

        case (true, .unavailable):
            // TODO: アラートを出す
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)

        case (true, .unknown):
            break

        case (false, _):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)
        }
    }

    private func reloadCloudStackIfNeeded(isCloudSyncEnabled: Bool) {
        guard isCloudSyncEnabled != self.cloudStack.isCloudSyncEnabled else { return }
        self.cloudStack.reload(isCloudSyncEnabled: isCloudSyncEnabled)
    }
}
