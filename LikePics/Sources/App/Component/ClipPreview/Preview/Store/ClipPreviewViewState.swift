//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import UIKit

struct ClipPreviewViewState: Equatable {
    let itemId: ClipItem.Identity
    let imageId: ImageContainer.Identity
    let imageSize: CGSize

    var source: ClipPreviewView.Source?

    var isDisplayingLoadingIndicator: Bool
    var isUserInteractionEnabled: Bool
    var isDismissed: Bool
}

extension ClipPreviewViewState {
    init(item: ClipItem) {
        self.itemId = item.id
        self.imageId = item.imageId
        self.imageSize = item.imageSize.cgSize

        source = nil

        isDisplayingLoadingIndicator = false
        isUserInteractionEnabled = true
        isDismissed = false
    }
}
