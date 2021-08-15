//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ClipItemInformationTransitionType {
    case custom(interactive: Bool)
    case `default`

    static let initialValue: Self = .custom(interactive: false)
}
