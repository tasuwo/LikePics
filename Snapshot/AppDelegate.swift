//
//  AppDelegate.swift
//  Snapshot
//
//  Created by Tasuku Tozawa on 2022/03/21.
//

import AppFeature
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    public private(set) var appDependencyContainer: AppDependencyContaining!
    private var clipsIntegrityValidator: ClipsIntegrityValidator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appDependencyContainer = DummyContainer()
        clipsIntegrityValidator = ClipsIntegrityValidator(dependency: appDependencyContainer)
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

extension AppDelegate: HasAppDependencyContainer {}
