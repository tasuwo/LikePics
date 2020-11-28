//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol CloudStackLoaderObserver: AnyObject {
    func didAccountChanged(_ loader: CloudStackLoader)
    func didDisabledICloudSyncByUnavailableAccount(_ loader: CloudStackLoader)
}

public class CloudStackLoader {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityStore: CloudAvailabilityStore
    private let cloudStack: CloudStack
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.CloudStackLoader")

    private var cancellableBag = Set<AnyCancellable>()

    public weak var observer: CloudStackLoaderObserver?

    // MARK: - Lifecycle

    public init(userSettingsStorage: UserSettingsStorageProtocol,
                cloudAvailabilityStore: CloudAvailabilityStore,
                cloudStack: CloudStack)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityStore = cloudAvailabilityStore
        self.cloudStack = cloudStack
    }

    // MARK: - Methods

    public func startObserveCloudAvailability() {
        self.cloudAvailabilityStore.state
            .sink { [weak self] availability in
                self?.queue.sync { self?.didUpdate(cloudAvailability: availability) }
            }
            .store(in: &self.cancellableBag)

        self.userSettingsStorage.enabledICloudSync
            .sink { [weak self] isICloudSyncEnabled in
                self?.queue.sync { self?.didUpdate(isICloudSyncEnabled: isICloudSyncEnabled) }
            }
            .store(in: &self.cancellableBag)
    }

    private func didUpdate(cloudAvailability: CloudAvailability) {
        let enabledICloudSync = self.userSettingsStorage.readEnabledICloudSync()
        switch (enabledICloudSync, cloudAvailability) {
        case (true, .available(.none)):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)

        case (true, .available(.accountChanged)):
            self.observer?.didAccountChanged(self)
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)

        case (true, .unavailable):
            self.observer?.didDisabledICloudSyncByUnavailableAccount(self)
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)

        case (true, .unknown):
            break

        case (false, _):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)
        }
    }

    private func didUpdate(isICloudSyncEnabled: Bool) {
        let cloudAvailability = self.cloudAvailabilityStore.state.value
        switch (isICloudSyncEnabled, cloudAvailability) {
        case (true, .available):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)

        case (true, .unavailable):
            self.observer?.didDisabledICloudSyncByUnavailableAccount(self)
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
