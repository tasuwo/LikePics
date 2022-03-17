//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Foundation

protocol SceneRootSetupViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func launchLikePics(_ intent: Intent?)
    func confirmAccountChanged()
    func confirmUnavailable()
    func confirmFailure()
}

class SceneRootSetupPresenter {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityService: CloudAvailabilityServiceProtocol
    private let intent: Intent?

    weak var view: SceneRootSetupViewProtocol?

    // MARK: - Lifecycle

    init(userSettingsStorage: UserSettingsStorageProtocol,
         cloudAvailabilityService: CloudAvailabilityServiceProtocol,
         intent: Intent?)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityService = cloudAvailabilityService
        self.intent = intent
    }

    func checkCloudAvailability() {
        self.view?.startLoading()

        cloudAvailabilityService.currentAvailability { [weak self] availability in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.view?.endLoading()

                let enabledICloudSync = self.userSettingsStorage.readEnabledICloudSync()

                switch (enabledICloudSync, availability) {
                case (true, .success(.available(.none))):
                    self.view?.launchLikePics(self.intent)

                case (true, .success(.available(.accountChanged))):
                    self.view?.confirmAccountChanged()

                case (true, .success(.unavailable)):
                    if self.userSettingsStorage.readIgnoreCloudUnavailableAlert() {
                        self.view?.launchLikePics(self.intent)
                    } else {
                        self.view?.confirmUnavailable()
                    }

                case (true, .failure):
                    self.view?.confirmFailure()

                case (false, _):
                    self.view?.launchLikePics(self.intent)
                }
            }
        }
    }

    func didConfirmAccountChanged() {
        self.view?.launchLikePics(intent)
    }

    func didConfirmUnavailable() {
        self.view?.launchLikePics(intent)
    }

    func didConfirmFailure() {
        self.view?.launchLikePics(intent)
    }

    func didTapDoNotShowUnavailableAlertAgain() {
        userSettingsStorage.set(ignoreCloudUnavailableAlert: true)
        view?.launchLikePics(intent)
    }
}
