//
//  AppDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Persistence
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let container: CurrentValueSubject<DependencyContainer?, Never> = .init(nil)
    let cloudStackLoader: CurrentValueSubject<CloudStackLoader?, Never> = .init(nil)

    private(set) var cloudAvailabilityService: CloudAvailabilityService!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
                AppDataLoader.loadAppData()
                UserSettingsStorage().set(enabledICloudSync: false)
            }
        #endif

        let cloudAvailabilityService = CloudAvailabilityService(cloudUsageContextStorage: CloudUsageContextStorage(),
                                                                cloudAccountService: CloudAccountService())

        self.cloudAvailabilityService = cloudAvailabilityService

        prepareDependencyContainer(by: cloudAvailabilityService)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // NOP
    }
}

extension AppDelegate {
    func prepareDependencyContainer(by cloudAvailabilityService: CloudAvailabilityService) {
        // swiftlint:disable:next unowned_variable_capture
        cloudAvailabilityService.currentAvailability { [unowned self, unowned cloudAvailabilityService] result in
            let isSyncEnabled = UserSettingsStorage().readEnabledICloudSync()

            let container: DependencyContainer

            switch (isSyncEnabled, result) {
            case (true, .success(.available(.none))):
                // swiftlint:disable:next force_try
                container = try! DependencyContainer(configuration: .init(isCloudSyncEnabled: true),
                                                     cloudAvailabilityObserver: cloudAvailabilityService)

            case (true, .success(.available(.accountChanged))),
                 (true, .success(.unavailable)),
                 (true, .failure),
                 (false, _):
                // swiftlint:disable:next force_try
                container = try! DependencyContainer(configuration: .init(isCloudSyncEnabled: false),
                                                     cloudAvailabilityObserver: cloudAvailabilityService)
            }

            self.container.send(container)
            self.cloudStackLoader.send(container.makeCloudStackLoader())
        }
    }
}
