//
//  AppDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import LikePicsCore
import Persistence
import UIKit

public class AppDelegate: UIResponder, UIApplicationDelegate {
    struct Singleton {
        let container: AppDependencyContainer
        let clipsIntegrityValidatorStore: Store<ClipsIntegrityValidatorState, ClipsIntegrityValidatorAction, ClipsIntegrityValidatorDependency>
    }

    let singleton: CurrentValueSubject<Singleton?, Never> = .init(nil)
    private(set) var cloudAvailabilityService: CloudAvailabilityService!

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let cloudAvailabilityService = CloudAvailabilityService(cloudUsageContextStorage: CloudUsageContextStorage(),
                                                                cloudAccountService: CloudAccountService())
        self.cloudAvailabilityService = cloudAvailabilityService

        prepareSingleton(by: cloudAvailabilityService)

        return true
    }

    // MARK: UISceneSession Lifecycle

    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    public func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // NOP
    }
}

extension AppDelegate {
    func prepareSingleton(by cloudAvailabilityService: CloudAvailabilityService) {
        // swiftlint:disable:next unowned_variable_capture
        cloudAvailabilityService.currentAvailability { [unowned self, unowned cloudAvailabilityService] result in
            let isSyncEnabled = UserSettingsStorage.shared.readEnabledICloudSync()

            let container: AppDependencyContainer

            switch (isSyncEnabled, result) {
            case (true, .success(.available(.none))):
                // swiftlint:disable:next force_try
                container = try! AppDependencyContainer(configuration: .init(isCloudSyncEnabled: true),
                                                        cloudAvailabilityObserver: cloudAvailabilityService)

            case (true, .success(.available(.accountChanged))),
                 (true, .success(.unavailable)),
                 (true, .failure),
                 (false, _):
                // swiftlint:disable:next force_try
                container = try! AppDependencyContainer(configuration: .init(isCloudSyncEnabled: false),
                                                        cloudAvailabilityObserver: cloudAvailabilityService)
            }

            let clipsIntegrityValidatorStore = container.makeClipsIntegrityValidatorStore()
            let context = Singleton(container: container,
                                    clipsIntegrityValidatorStore: clipsIntegrityValidatorStore)
            self.singleton.send(context)

            DarwinNotificationCenter.default.addObserver(self, for: .shareExtensionDidCompleteRequest) { [weak self] _ in
                self?.singleton.value?.clipsIntegrityValidatorStore.execute(.shareExtensionDidCompleteRequest)
            }
            clipsIntegrityValidatorStore.execute(.didLaunchApp)
        }
    }
}
