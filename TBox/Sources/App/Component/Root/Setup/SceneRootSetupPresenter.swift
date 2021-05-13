//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

protocol SceneRootSetupViewProtocol: AnyObject {
    func startLoading()
    func endLoading()
    func launchLikePics()
    func confirmAccountChanged()
    func confirmUnavailable()
}

class SceneRootSetupPresenter {
    private let userSettingsStorage: UserSettingsStorageProtocol
    private let cloudAvailabilityService: CloudAvailabilityService

    weak var view: SceneRootSetupViewProtocol?

    // MARK: - Lifecycle

    init(userSettingsStorage: UserSettingsStorageProtocol,
         cloudAvailabilityService: CloudAvailabilityService)
    {
        self.userSettingsStorage = userSettingsStorage
        self.cloudAvailabilityService = cloudAvailabilityService
    }

    func checkCloudAvailability() {
        self.view?.startLoading()

        // TODO: 必要に応じて表示をスキップする
        cloudAvailabilityService.currentAvailability { [weak self] availability in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.view?.endLoading()

                let enabledICloudSync = self.userSettingsStorage.readEnabledICloudSync()

                switch (enabledICloudSync, availability) {
                case (true, .success(.available(.none))):
                    self.view?.launchLikePics()

                case (true, .success(.available(.accountChanged))):
                    self.view?.confirmAccountChanged()

                case (true, .success(.unavailable)):
                    self.view?.confirmUnavailable()

                case (true, .failure):
                    // TODO: 別の文言を表示する
                    self.view?.confirmUnavailable()

                case (false, _):
                    self.view?.launchLikePics()
                }
            }
        }
    }

    func didConfirmAccountChanged() {
        self.view?.launchLikePics()
    }

    func didConfirmUnavailable() {
        self.view?.launchLikePics()
    }
}
