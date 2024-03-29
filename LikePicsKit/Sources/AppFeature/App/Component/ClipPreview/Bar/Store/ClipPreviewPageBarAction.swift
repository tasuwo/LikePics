//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain
import UIKit

enum ClipPreviewPageBarAction: Action {
    // MARK: View Life-Cycle

    case sizeClassChanged(isVerticalSizeClassCompact: Bool)

    // MARK: State Observation

    case updatedCurrentIndex(Int?)
    case updatedClipItems([ClipItem])
    case updatedPlaying(Bool)

    // MARK: Gesture

    case didTapView
    case willBeginZoom

    // MARK: Bar Button

    case backButtonTapped
    case infoButtonTapped
    case playButtonTapped
    case pauseButtonTapped
    case playConfigButtonTapped
    case browseButtonTapped
    case addButtonTapped
    case shareButtonTapped
    case deleteButtonTapped
    case listButtonTapped

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
