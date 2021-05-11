//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol AppRootSetupViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func launchLikePics(configuration: DependencyContainerConfiguration, service: CloudAvailabilityService)
    func confirmAccountChanged()
    func confirmUnavailable()
}

class AppRootSetupPresenter {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityService: CloudAvailabilityService

    private var subscription: AnyCancellable?

    weak var view: AppRootSetupViewProtocol?

    // MARK: - Lifecycle

    init(userSettingsStorage: UserSettingsStorageProtocol,
         cloudAvailabilityService: CloudAvailabilityService)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityService = cloudAvailabilityService
    }

    func checkCloudAvailability() {
        self.view?.startLoading()

        subscription = self.cloudAvailabilityService.availability
            .compactMap { $0 }
            .catch { _ in Just(.unavailable) } // TODO: 別のエラー文言を表示する
            .combineLatest(userSettingsStorage.enabledICloudSync)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] availability, enabledICloudSync in
                guard let self = self else { return }

                self.view?.endLoading()

                switch (enabledICloudSync, availability) {
                case (true, .available(.none)):
                    self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: true),
                                              service: self.cloudAvailabilityService)

                case (true, .available(.accountChanged)):
                    self.view?.confirmAccountChanged()

                case (true, .unavailable):
                    self.view?.confirmUnavailable()

                case (false, _):
                    self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: false),
                                              service: self.cloudAvailabilityService)
                }

                self.subscription?.cancel()
            }
    }

    func didConfirmAccountChanged() {
        self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: false),
                                  service: self.cloudAvailabilityService)
    }

    func didConfirmUnavailable() {
        self.view?.launchLikePics(configuration: .init(isCloudSyncEnabled: false),
                                  service: self.cloudAvailabilityService)
    }
}
