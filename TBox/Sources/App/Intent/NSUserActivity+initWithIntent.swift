//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

// swiftlint:disable force_try force_unwrapping

extension NSUserActivity {
    static func make(with intent: Intent) -> NSUserActivity {
        let userActivity = NSUserActivity(activityType: SceneDelegate.MainSceneActivityType)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(intent)
        let string = String(data: data, encoding: .utf8)! as NSString
        userActivity.addUserInfoEntries(from: [SceneDelegate.intentKey: string])
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
