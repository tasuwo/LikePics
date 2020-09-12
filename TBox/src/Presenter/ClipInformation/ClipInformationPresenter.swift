//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipInformationViewProtocol: AnyObject {}

class ClipInformationViewPresenter {
    let clip: Clip

    // MARK: - Lifecycle

    init(clip: Clip) {
        self.clip = clip
    }
}
