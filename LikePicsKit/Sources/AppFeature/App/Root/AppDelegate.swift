//
//  AppDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Environment
import UIKit

public class AppDelegate: UIResponder, UIApplicationDelegate {
    private(set) var appDependencyContainer: AppDependencyContaining!
    private var clipsIntegrityValidator: ClipsIntegrityValidator!

    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // swiftlint:disable:next force_try
        self.appDependencyContainer = try! AppDependencyContainer()
        self.clipsIntegrityValidator = ClipsIntegrityValidator(dependency: appDependencyContainer)

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
