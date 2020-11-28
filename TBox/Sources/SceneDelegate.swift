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
    var cloudAvailabilityObserver: CloudAvailabilityObserver!
    var dependencyContainer: DependencyContainer?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        #if DEBUG
            if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
                AppDataLoader.loadAppData()
            }
        #endif

        let cloudUsageContextStorage = CloudUsageContextStorage()
        let cloudAvailabilityResolver = CurrentICloudAccountResolver.self
        let cloudAvailabilityObserver = CloudAvailabilityObserver(cloudUsageContextStorage: cloudUsageContextStorage,
                                                                  cloudAvailabilityResolver: cloudAvailabilityResolver)
        let presenter = AppRootSetupPresenter(userSettingsStorage: UserSettingsStorage(),
                                              cloudAvailabilityStore: cloudAvailabilityObserver)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = AppRootSetupViewController(presenter: presenter, launcher: self)
        window.makeKeyAndVisible()

        self.window = window
        self.cloudAvailabilityObserver = cloudAvailabilityObserver

        self.setupAppearance()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // TODO: 実行頻度を考える
        if self.dependencyContainer?.persistService.persistIfNeeded() == false {
            self.dependencyContainer?.integrityValidationService.validateAndFixIntegrityIfNeeded()
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    private func setupAppearance() {
        UISwitch.appearance().onTintColor = Asset.likePicsSwitchClient.color
        self.window?.tintColor = Asset.likePicsRedClient.color
    }
}

extension SceneDelegate: MainAppLauncher {
    // MARK: - MainAppLauncher

    func launch(by configuration: DependencyContainerConfiguration) {
        do {
            let container = try DependencyContainer(configuration: configuration,
                                                    cloudAvailabilityObserver: self.cloudAvailabilityObserver)
            self.dependencyContainer = container

            let rootViewController = AppRootTabBarController(factory: container)

            self.window?.rootViewController?.dismiss(animated: true) {
                self.window?.rootViewController = rootViewController
            }

            // TODO: 実行頻度を考える
            container.integrityValidationService.validateAndFixIntegrityIfNeeded()
        } catch {
            RootLogger.shared.write(ConsoleLog(level: .critical, message: "Unabled to launch app. \(error.localizedDescription)"))
            fatalError("Unable to launch app.")
        }
    }
}
