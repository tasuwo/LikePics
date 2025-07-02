//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension NSUserActivity {
    static func make(with intent: Intent, appBundle: Bundle) -> NSUserActivity? {
        guard let mainSceneActivityType = IntentConfiguration.mainSceneActivityType(appBundle: appBundle),
            let data = try? JSONEncoder().encode(intent),
            let jsonString = String(data: data, encoding: .utf8)
        else { return nil }
        let userActivity = NSUserActivity(activityType: mainSceneActivityType)
        userActivity.addUserInfoEntries(from: [IntentConfiguration.intentKey: jsonString])
        return userActivity
    }

    func intent(appBundle: Bundle) -> Intent? {
        guard activityType == IntentConfiguration.mainSceneActivityType(appBundle: appBundle),
            let string = userInfo?[IntentConfiguration.intentKey] as? String,
            let data = string.data(using: .utf8)
        else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Intent.self, from: data)
    }
}
