//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

enum IntentConfiguration {
    static let intentKey = "intent"

    static func mainSceneActivityType(appBundle: Bundle) -> String? {
        let activityTypes = appBundle.infoDictionary?["NSUserActivityTypes"] as? [String]
        return activityTypes?[0]
    }
}
