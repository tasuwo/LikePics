//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension SceneDelegate {
    static let MainSceneActivityType: String = {
        let activityTypes = Bundle.main.infoDictionary?["NSUserActivityTypes"] as? [String]
        // swiftlint:disable:next force_unwrapping
        return activityTypes![0]
    }()

    static let intentKey = "intent"

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        return scene.userActivity
    }
}
