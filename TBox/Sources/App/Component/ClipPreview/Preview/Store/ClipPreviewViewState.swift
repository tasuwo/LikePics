//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

struct ClipPreviewViewState: Equatable {
    enum Modal: Equatable {
        case albumSelection(UUID)
    }

    let itemId: ClipItem.Identity
    let imageId: ImageContainer.Identity
    let imageSize: CGSize

    var source: ClipPreviewView.Source?

    var isDisplayingLoadingIndicator: Bool
    var isUserInteractionEnabled: Bool
    var isDismissed: Bool

    var modal: Modal?
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
