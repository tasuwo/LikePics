//
//  SceneDelegate.swift
//  TBox
//
//  Created by Tasuku Tozawa on 2020/08/07.
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Persistence
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private var sceneDependencyContainer: SceneDependencyContainer!
    private var subscription: Set<AnyCancellable> = .init()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let presenter = AppRootSetupPresenter(userSettingsStorage: UserSettingsStorage(),
                                              cloudAvailabilityService: delegate.cloudAvailabilityService)
        let rootViewController = AppRootSetupViewController(presenter: presenter, launcher: self)

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        self.window = window

        self.setupAppearance()
    }

    private func setupAppearance() {
        UISwitch.appearance().onTintColor = Asset.Color.likePicsSwitchClient.color
        self.window?.tintColor = Asset.Color.likePicsRedClient.color
    }
}

extension SceneDelegate: MainAppLauncher {
    // MARK: - MainAppLauncher

    func launch() {
        // swiftlint:disable:next force_cast
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.singleton
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            // swiftlint:disable:next unowned_variable_capture
            .sink { [unowned self] singleton in
                self.sceneDependencyContainer = SceneDependencyContainer(sceneResolver: self, container: singleton.container)

                // TODO: iPad/iPhoneで切り替える
                let rootViewController = AppRootTabBarController(factory: self.sceneDependencyContainer,
                                                                 clipsIntegrityValidatorStore: singleton.clipsIntegrityValidatorStore,
                                                                 logger: singleton.container.logger)

                self.window?.rootViewController?.dismiss(animated: true) {
                    self.window?.rootViewController = rootViewController
                }

                singleton.cloudStackLoader.observers.append(.init(value: rootViewController))

                self.subscription.first?.cancel()
            }
            .store(in: &subscription)
    }
}
