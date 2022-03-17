//
//  SceneDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import CompositeKit
import Domain
import LikePicsUIKit
import Persistence
import UIKit

public class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    public var window: UIWindow?

    private var sceneDependencyContainer: SceneDependencyContainer!
    private var subscriptions: Set<AnyCancellable> = .init()

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let presenter = SceneRootSetupPresenter(userSettingsStorage: UserSettingsStorage.shared,
                                                cloudAvailabilityService: delegate.appDependencyContainer._cloudAvailabilityService,
                                                intent: session.stateRestorationActivity?.intent)
        let rootViewController = SceneRootSetupViewController(presenter: presenter, launcher: self)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        UserSettingsStorage.shared
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
}

extension SceneDelegate: MainAppLauncher {
    // MARK: - MainAppLauncher

    func launch(_ intent: Intent?) {
        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.sceneDependencyContainer = SceneDependencyContainer(sceneResolver: self, container: delegate.appDependencyContainer)

        let rootViewController: SceneRootViewController
        if UIDevice.current.userInterfaceIdiom == .pad {
            rootViewController = SceneRootSplitViewController(factory: self.sceneDependencyContainer,
                                                              intent: intent,
                                                              logger: delegate.appDependencyContainer.logger)
        } else {
            rootViewController = SceneRootTabBarController(factory: self.sceneDependencyContainer,
                                                           intent: intent,
                                                           logger: delegate.appDependencyContainer.logger)
        }

        self.window?.rootViewController?.dismiss(animated: true) {
            self.window?.rootViewController = rootViewController
        }

        delegate.appDependencyContainer.cloudStackLoader.observers.append(.init(value: rootViewController))
    }
}
