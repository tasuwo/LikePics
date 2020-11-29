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
            // 初回起動時の分を除く
            .dropFirst()
            .sink { [weak self] availability in
                self?.queue.sync { self?.didUpdate(cloudAvailability: availability) }
            }
            .store(in: &self.cancellableBag)

        self.userSettingsStorage.enabledICloudSync
            // 初回起動時の分を除く
            .dropFirst()
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
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)
            // NOTE: アカウント変更の場合は、リロードの成否にかかわらず通知する
            self.observer?.didAccountChanged(self)

        case (true, .unavailable):
            if self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false) {
                self.observer?.didDisabledICloudSyncByUnavailableAccount(self)
            }

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
            if self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false) {
                self.observer?.didDisabledICloudSyncByUnavailableAccount(self)
            }

        case (true, .unknown):
            break

        case (false, _):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)
        }
    }

    @discardableResult
    private func reloadCloudStackIfNeeded(isCloudSyncEnabled: Bool) -> Bool {
        guard isCloudSyncEnabled != self.cloudStack.isCloudSyncEnabled else { return false }
        self.cloudStack.reload(isCloudSyncEnabled: isCloudSyncEnabled)
        return true
    }
}
