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
    struct Context {
        let container: DependencyContainer
        let cloudStackLoader: CloudStackLoader
        let integrityResolvingViewModel: ClipIntegrityResolvingViewModelType
    }

    let context: CurrentValueSubject<Context?, Never> = .init(nil)
    private var subscriptions: Set<AnyCancellable> = .init()
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

            let cloudStackLoader = container.makeCloudStackLoader()
            let integrityResolvingViewModel = container.makeClipIntegrityResolvingViewModel()

            let context = Context(container: container,
                                  cloudStackLoader: cloudStackLoader,
                                  integrityResolvingViewModel: integrityResolvingViewModel)
            self.context.send(context)

            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
                .sink { _ in integrityResolvingViewModel.inputs.sceneDidBecomeActive.send(()) }
                .store(in: &self.subscriptions)

            integrityResolvingViewModel.inputs.didLaunchApp.send(())

            cloudStackLoader.startObserveCloudAvailability()
        }
    }
}
