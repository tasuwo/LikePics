//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum ClipPreviewPageViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case pageChanged(index: Int)
    case clipUpdated(Clip)
    case failedToLoadClip
    case clipsUpdated([Clip])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Transition

    case clipInformationViewPresented

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
