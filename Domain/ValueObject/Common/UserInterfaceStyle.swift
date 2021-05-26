//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public enum UserInterfaceStyle: String {
    case light
    case dark
    case unspecified
}

public extension UserInterfaceStyle {
    var uiUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light

        case .dark:
            return .dark

        case .unspecified:
            return .unspecified
        }
    }
}
