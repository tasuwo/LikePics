//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum UserInterfaceStyle: String {
    case light
    case dark
    case unspecified
}

#if os(iOS)

import UIKit

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

#endif
