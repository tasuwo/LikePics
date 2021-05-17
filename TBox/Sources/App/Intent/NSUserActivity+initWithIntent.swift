//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension NSUserActivity {
    static func make(with intentJsonString: String) -> NSUserActivity {
        let userActivity = NSUserActivity(activityType: SceneDelegate.MainSceneActivityType)
        userActivity.addUserInfoEntries(from: [SceneDelegate.intentKey: intentJsonString])
        return userActivity
    }

    var intent: Intent? {
        guard activityType == SceneDelegate.MainSceneActivityType,
              let string = userInfo?[SceneDelegate.intentKey] as? String,
              let data = string.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Intent.self, from: data)
    }
}
