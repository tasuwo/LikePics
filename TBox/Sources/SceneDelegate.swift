//
//  SceneDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain
import Persistence
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var cloudStackLoader: CloudStackLoader?
    var dependencyContainer: DependencyContainer?
    var window: UIWindow?

    private let launchQueue = DispatchQueue(label: "net.tasuwo.TBox.SceneDelegate.launch")

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        #if DEBUG
            if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
                AppDataLoader.loadAppData()
                UserSettingsStorage().set(enabledICloudSync: false)
            }
        #endif

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = self.makeAppRootSetupViewController()
        window.makeKeyAndVisible()

        self.window = window

        self.setupAppearance()
    }

    private func makeAppRootSetupViewController() -> UIViewController {
        let cloudUsageContextStorage = CloudUsageContextStorage()
        let cloudAvailabilityResolver = CurrentICloudAccountResolver.self
        let cloudAvailabilityObserver = CloudAvailabilityObserver(cloudUsageContextStorage: cloudUsageContextStorage,
                                                                  cloudAvailabilityResolver: cloudAvailabilityResolver)
        let presenter = AppRootSetupPresenter(userSettingsStorage: UserSettingsStorage(),
                                              cloudAvailabilityStore: cloudAvailabilityObserver)
        return AppRootSetupViewController(presenter: presenter, launcher: self)
    }

    private func setupAppearance() {
        UISwitch.appearance().onTintColor = Asset.Color.likePicsSwitchClient.color
        self.window?.tintColor = Asset.Color.likePicsRedClient.color
    }
}

extension SceneDelegate: MainAppLauncher {
    // MARK: - MainAppLauncher

    func launch(configuration: DependencyContainerConfiguration, observer: CloudAvailabilityObserver) {
        do {
            let container = try DependencyContainer(configuration: configuration,
                                                    cloudAvailabilityObserver: observer)
            self.dependencyContainer = container

            let rootViewModel = container.makeClipIntegrityResolvingViewModel()
            // let rootViewController = AppRootTabBarController(factory: container, integrityViewModel: rootViewModel)
            let rootViewController = AppRootSplitViewController(factory: container, integrityViewModel: rootViewModel)

            self.window?.rootViewController?.dismiss(animated: true) {
                self.window?.rootViewController = rootViewController
            }

            self.cloudStackLoader = container.makeCloudStackLoader()
            // self.cloudStackLoader?.observer = rootViewController

            self.cloudStackLoader?.startObserveCloudAvailability()
        } catch {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Unabled to launch app. \(error.localizedDescription)"))
            fatalError("Unable to launch app.")
        }
    }
}
