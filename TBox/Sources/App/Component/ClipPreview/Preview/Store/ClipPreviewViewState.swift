//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

struct ClipPreviewViewState: Equatable {
    var itemId: ClipItem.Identity
    var imageId: ImageContainer.Identity
    var imageSize: CGSize

    var source: ClipPreviewView.Source?

    var isDisplayingLoadingIndicator: Bool
    var isUserInteractionEnabled: Bool
    var isDismissed: Bool
}
