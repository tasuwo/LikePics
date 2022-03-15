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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var sceneDependencyContainer: SceneDependencyContainer!
    private var subscription: Set<AnyCancellable> = .init()

    private var userSettingsStorage: UserSettingsStorage!
    private var uiStyleSubscription: AnyCancellable?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let presenter = SceneRootSetupPresenter(userSettingsStorage: UserSettingsStorage.shared,
                                                cloudAvailabilityService: delegate.cloudAvailabilityService,
                                                intent: session.stateRestorationActivity?.intent)
        let rootViewController = SceneRootSetupViewController(presenter: presenter, launcher: self)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        userSettingsStorage = UserSettingsStorage.shared
        uiStyleSubscription = userSettingsStorage
            .userInterfaceStyle
            .map { $0.uiUserInterfaceStyle }
            .sink { [window] style in window.overrideUserInterfaceStyle = style }

        self.window = window

        self.setupAppearance()
    }

    private func setupAppearance() {
        UISwitch.appearance().onTintColor = Asset.Color.likePicsSwitch.color
        self.window?.tintColor = Asset.Color.likePicsRed.color
    }

    func sceneWillResignActive(_ scene: UIScene) {
        window?.windowScene?.userActivity?.resignCurrent()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        window?.windowScene?.userActivity?.becomeCurrent()
    }
}

extension SceneDelegate: MainAppLauncher {
    // MARK: - MainAppLauncher

    func launch(_ intent: Intent?) {
        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.singleton
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            // swiftlint:disable:next unowned_variable_capture
            .sink { [unowned self] singleton in
                self.sceneDependencyContainer = SceneDependencyContainer(sceneResolver: self, container: singleton.container)

                let rootViewController: SceneRootViewController
                if UIDevice.current.userInterfaceIdiom == .pad {
                    rootViewController = SceneRootSplitViewController(factory: self.sceneDependencyContainer,
                                                                      clipsIntegrityValidatorStore: singleton.clipsIntegrityValidatorStore,
                                                                      intent: intent,
                                                                      logger: singleton.container.logger)
                } else {
                    rootViewController = SceneRootTabBarController(factory: self.sceneDependencyContainer,
                                                                   clipsIntegrityValidatorStore: singleton.clipsIntegrityValidatorStore,
                                                                   intent: intent,
                                                                   logger: singleton.container.logger)
                }

                self.window?.rootViewController?.dismiss(animated: true) {
                    self.window?.rootViewController = rootViewController
                }

                singleton.cloudStackLoader.observers.append(.init(value: rootViewController))

                self.subscription.first?.cancel()
            }
            .store(in: &subscription)
    }
}
