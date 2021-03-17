//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipPreviewPageViewCacheAction: Action {
    // MARK: View Life-Cycle

    case viewWillDisappear
    case viewDidAppear

    // MARK: Transition

    case pageChanged(Clip.Identity, ClipItem.Identity)
}
