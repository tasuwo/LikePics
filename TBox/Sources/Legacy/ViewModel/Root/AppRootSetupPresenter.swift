//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol AppRootSetupViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func launchLikePics(configuration: DependencyContainerConfiguration, observer: CloudAvailabilityObserver)
    func confirmAccountChanged()
    func confirmUnavailable()
}

class AppRootSetupPresenter {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityObserver: CloudAvailabilityObserver

    private var subscriptions = Set<AnyCancellable>()

    weak var view: AppRootSetupViewProtocol?

    // MARK: - Lifecycle

    init(userSettingsStorage: UserSettingsStorageProtocol,
         cloudAvailabilityStore: CloudAvailabilityObserver)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityObserver = cloudAvailabilityStore
    }

    func checkCloudAvailability() {
        self.view?.startLoading()

        self.cloudAvailabilityObserver.state
            .compactMap { $0 }
            .combineLatest(self.userSettingsStorage.enabledICloudSync)
            .sink { [weak self] availability, enabledICloudSync in
                self?.didFetch(availability: availability, enabledICloudSync: enabledICloudSync)
            }
            .store(in: &self.subscriptions)
    }

    func didConfirmAccountChanged() {
        self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: false),
                                  observer: self.cloudAvailabilityObserver)
    }

    func didConfirmUnavailable() {
        self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: false),
                                  observer: self.cloudAvailabilityObserver)
    }

    private func didFetch(availability: CloudAvailability, enabledICloudSync: Bool) {
        self.subscriptions.first?.cancel()
        self.view?.endLoading()

        switch (enabledICloudSync, availability) {
        case (true, .available(.none)):
            self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: true),
                                      observer: self.cloudAvailabilityObserver)

        case (true, .available(.accountChanged)):
            self.view?.confirmAccountChanged()

        case (true, .unavailable):
            self.view?.confirmUnavailable()

        case (false, _):
            self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: false),
                                      observer: self.cloudAvailabilityObserver)
        }
    }
}
