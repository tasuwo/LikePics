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
        delegate.context
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { context in
                // TODO: iPad/iPhoneで切り替える
                let rootViewController = AppRootTabBarController(factory: context.container,
                                                                 integrityViewModel: context.integrityResolvingViewModel,
                                                                 logger: context.container.logger)

                self.window?.rootViewController?.dismiss(animated: true) {
                    self.window?.rootViewController = rootViewController
                }

                context.cloudStackLoader.observers.append(.init(value: rootViewController))
            }
            .store(in: &subscription)
    }
}
