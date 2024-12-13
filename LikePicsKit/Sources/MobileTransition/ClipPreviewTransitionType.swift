//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ClipPreviewTransitionType: Sendable {
    case custom(interactive: Bool)
    case `default`

    public static let initialValue: Self = .custom(interactive: false)
}
