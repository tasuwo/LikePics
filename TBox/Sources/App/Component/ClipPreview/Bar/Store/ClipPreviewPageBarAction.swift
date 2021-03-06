//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit
import UIKit

enum ClipPreviewPageBarAction: Action {
    // MARK: View Life-Cycle

    case sizeClassChanged(isVerticalSizeClassCompact: Bool)

    // MARK: Gesture

    case didTapView
    case willBeginZoom

    // MARK: Bar Button

    case backButtonTapped
    case infoButtonTapped
    case browseButtonTapped
    case addButtonTapped
    case shareButtonTapped
    case deleteButtonTapped

    // MARK: Alert Completion

    case alertDeleteClipConfirmed
    case alertDeleteClipItemConfirmed

    case alertTagAdditionConfirmed
    case alertAlbumAdditionConfirmed

    case alertShareClipConfirmed
    case alertShareItemConfirmed
    case alertShareDismissed(Bool)

    case alertDismissed
}
