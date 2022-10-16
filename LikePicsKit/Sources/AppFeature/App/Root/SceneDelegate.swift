//
//  SceneDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import LikePicsUIKit
import UIKit

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?

    private var sceneDependencyContainer: SceneDependencyContainer!
    private var subscriptions: Set<AnyCancellable> = .init()

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! HasAppDependencyContainer
        self.sceneDependencyContainer = SceneDependencyContainer(sceneResolver: self, container: delegate.appDependencyContainer)

        let intent = session.stateRestorationActivity?.intent(appBundle: delegate.appDependencyContainer.appBundle)
        let rootViewController: SceneRootViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            rootViewController = SceneRootSplitViewController(factory: self.sceneDependencyContainer, intent: intent)
        } else {
            rootViewController = SceneRootTabBarController(factory: self.sceneDependencyContainer, intent: intent)
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        delegate.appDependencyContainer.userSettingStorage
            .userInterfaceStyle
            .map { $0.uiUserInterfaceStyle }
            .sink { [window] style in window.overrideUserInterfaceStyle = style }
            .store(in: &self.subscriptions)

        self.window = window

        self.setupAppearance()
    }

    private func setupAppearance() {
        UISwitch.appearance().onTintColor = Asset.Color.likePicsSwitch.color
        self.window?.tintColor = Asset.Color.likePicsRed.color
    }

    public func sceneWillResignActive(_ scene: UIScene) {
        window?.windowScene?.userActivity?.resignCurrent()
    }

    public func sceneDidBecomeActive(_ scene: UIScene) {
        window?.windowScene?.userActivity?.becomeCurrent()
    }

    public func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
}
