//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol AppRootSetupViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func launchLikePics(by configuration: DependencyContainerConfiguration)
    func confirmAccountChanged()
    func confirmUnavailable()
}

class AppRootSetupPresenter {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityStore: CloudAvailabilityStore

    private var cancellableBag = Set<AnyCancellable>()

    weak var view: AppRootSetupViewProtocol?

    // MARK: - Lifecycle

    init(userSettingsStorage: UserSettingsStorageProtocol,
         cloudAvailabilityStore: CloudAvailabilityStore)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityStore = cloudAvailabilityStore
    }

    func setup() {
        self.view?.startLoading()

        self.cloudAvailabilityStore.state
            .compactMap { $0 }
            .combineLatest(self.userSettingsStorage.enabledICloudSync)
            .sink { [weak self] availability, enabledICloudSync in
                self?.didFetch(availability: availability, enabledICloudSync: enabledICloudSync)
            }
            .store(in: &self.cancellableBag)
    }

    func didConfirmAccountChanged() {
        self.view?.launchLikePics(by: .init(isCloudSyncEnabled: false))
    }

    func didConfirmUnavailable() {
        self.view?.launchLikePics(by: .init(isCloudSyncEnabled: false))
    }

    private func didFetch(availability: CloudAvailability, enabledICloudSync: Bool) {
        self.cancellableBag.first?.cancel()
        self.view?.endLoading()

        switch (enabledICloudSync, availability) {
        case (true, .available(.none)):
            self.view?.launchLikePics(by: .init(isCloudSyncEnabled: true))

        case (true, .available(.accountChanged)):
            self.view?.confirmAccountChanged()

        case (true, .unavailable):
            self.view?.confirmUnavailable()

        case (false, _):
            self.view?.launchLikePics(by: .init(isCloudSyncEnabled: false))
        }
    }
}
