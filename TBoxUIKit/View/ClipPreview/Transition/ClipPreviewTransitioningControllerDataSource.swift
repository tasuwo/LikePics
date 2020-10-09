//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ClipPreviewDismissalMode {
    case custom(interactive: Bool)
    case `default`
}

public protocol ClipPreviewTransitioningControllerDataSource: AnyObject {
    var dismissalMode: ClipPreviewDismissalMode { get }
}
