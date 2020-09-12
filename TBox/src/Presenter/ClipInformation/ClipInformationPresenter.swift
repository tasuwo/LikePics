//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol ClipInformationViewProtocol: AnyObject {}

class ClipInformationPresenter {
    let clip: Clip
    let item: ClipItem

    // MARK: - Lifecycle

    init(clip: Clip, item: ClipItem) {
        self.clip = clip
        self.item = item
    }
}
