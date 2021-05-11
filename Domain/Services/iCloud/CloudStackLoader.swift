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
    private let cloudAvailabilityService: CloudAvailabilityServiceProtocol
    private let cloudStack: CloudStack
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.CloudStackLoader")

    private var subscriptions = Set<AnyCancellable>()

    public weak var observer: CloudStackLoaderObserver?

    // MARK: - Lifecycle

    public init(userSettingsStorage: UserSettingsStorageProtocol,
                cloudAvailabilityService: CloudAvailabilityServiceProtocol,
                cloudStack: CloudStack)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityService = cloudAvailabilityService
        self.cloudStack = cloudStack
    }

    // MARK: - Methods

    public func startObserveCloudAvailability() {
        self.cloudAvailabilityService.state
            // 初回起動時の分を除く
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] availability in
                self?.queue.sync { self?.didUpdate(cloudAvailability: availability) }
            }
            .store(in: &self.subscriptions)

        self.userSettingsStorage.enabledICloudSync
            // 初回起動時の分を除く
            .dropFirst()
            .sink { [weak self] isICloudSyncEnabled in
                self?.queue.sync { self?.didUpdate(isICloudSyncEnabled: isICloudSyncEnabled) }
            }
            .store(in: &self.subscriptions)
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

        case (false, _):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)
        }
    }

    private func didUpdate(isICloudSyncEnabled: Bool) {
        guard let cloudAvailability = self.cloudAvailabilityService.state.value else { return }
        switch (isICloudSyncEnabled, cloudAvailability) {
        case (true, .available):
            self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)

        case (true, .unavailable):
            if self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false) {
                self.observer?.didDisabledICloudSyncByUnavailableAccount(self)
            }

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
