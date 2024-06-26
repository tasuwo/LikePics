//
//  AppDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import AppFeature
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private(set) var appDependencyContainer: AppDependencyContaining!
    private var clipsIntegrityValidator: ClipsIntegrityValidator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // swiftlint:disable:next force_try
        self.appDependencyContainer = try! AppDependencyContainer(appBundle: Bundle.main)
        self.clipsIntegrityValidator = ClipsIntegrityValidator(dependency: appDependencyContainer)

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

extension AppDelegate: @preconcurrency HasAppDependencyContainer {}
