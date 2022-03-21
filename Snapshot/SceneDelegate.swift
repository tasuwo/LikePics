//
//  SceneDelegate.swift
//  Snapshot
//
//  Created by Tasuku Tozawa on 2022/03/21.
//

import AppFeature
import LikePicsUIKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var sceneDependencyContainer: SceneDependencyContainer!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.sceneDependencyContainer = SceneDependencyContainer(sceneResolver: self, container: delegate.appDependencyContainer)

        let rootViewController: SceneRootViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            rootViewController = SceneRootSplitViewController(factory: self.sceneDependencyContainer, intent: nil)
        } else {
            rootViewController = SceneRootTabBarController(factory: self.sceneDependencyContainer, intent: nil)
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        self.window = window

        self.setupAppearance()
    }

    private func setupAppearance() {
        UISwitch.appearance().onTintColor = Asset.Color.likePicsSwitch.color
        self.window?.tintColor = Asset.Color.likePicsRed.color
    }
}

extension SceneDelegate: SceneResolvable {
    func resolveScene() -> UIWindowScene? { window?.windowScene }
}
