//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Foundation

/// @mockable
public protocol CloudStackLoaderObserver: AnyObject {
    func didAccountChanged(_ loader: CloudStackLoadable)
    func didDisabledICloudSyncByUnavailableAccount(_ loader: CloudStackLoadable)
}

/// @mockable
public protocol CloudStackLoadable {
    func startObserveCloudAvailability()
    func set(observer: CloudStackLoaderObserver)
}

public class CloudStackLoader {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityService: CloudAvailabilityServiceProtocol
    private let cloudStack: CloudStack
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.CloudStackLoader")

    private var subscriptions = Set<AnyCancellable>()

    private var observers: WeakContainerSet<CloudStackLoaderObserver> = .init()

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

    @discardableResult
    private func reloadCloudStackIfNeeded(isCloudSyncEnabled: Bool) -> Bool {
        guard isCloudSyncEnabled != self.cloudStack.isCloudSyncEnabled else { return false }
        self.cloudStack.reload(isCloudSyncEnabled: isCloudSyncEnabled)
        return true
    }
}

extension CloudStackLoader: CloudStackLoadable {
    // MARK: - CloudStackLoadable

    public func startObserveCloudAvailability() {
        self.cloudAvailabilityService.availability
            .compactMap { $0 }
            .catch { _ in Just(.unavailable) }
            .combineLatest(userSettingsStorage.enabledICloudSync)
            .sink { availability, enabledICloudSync in
                switch (enabledICloudSync, availability) {
                case (true, .available(.none)):
                    self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)

                case (true, .available(.accountChanged)):
                    self.reloadCloudStackIfNeeded(isCloudSyncEnabled: true)
                    // NOTE: アカウント変更の場合は、リロードの成否にかかわらず通知する
                    self.observers.forEach { $0.value?.didAccountChanged(self) }

                case (true, .unavailable):
                    if self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false) {
                        self.observers.forEach { $0.value?.didDisabledICloudSyncByUnavailableAccount(self) }
                    }

                case (false, _):
                    self.reloadCloudStackIfNeeded(isCloudSyncEnabled: false)
                }
            }
            .store(in: &subscriptions)
    }

    public func set(observer: CloudStackLoaderObserver) {
        self.observers.append(.init(value: observer))
    }
}
