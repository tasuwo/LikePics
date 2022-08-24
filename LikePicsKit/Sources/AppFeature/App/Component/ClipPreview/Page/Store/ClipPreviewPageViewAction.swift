//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain
import Foundation

enum ClipPreviewPageViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case pageChanged(indexPath: ClipCollection.IndexPath)
    case failedToLoadClip
    case clipsUpdated([Clip])
    case settingUpdated(isSomeItemsHidden: Bool)
    case playConfigUpdated(config: ClipPreviewPlayConfiguration)
    case willBeginTransition
    case didBeginPan
    case willBeginZoom

    // MARK: Transition

    case clipInformationViewPresented
    case nextPageRequested(UUID, at: ClipCollection.IndexPath)

    // MARK: Bar

    case barEventOccurred(ClipPreviewPageBarEvent)

    // MARK: Modal Completion

    case tagsSelected(Set<Tag.Identity>?)
    case albumsSelected(Album.Identity?)
    case itemRequested(ClipItem.Identity?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case alertDismissed
}
