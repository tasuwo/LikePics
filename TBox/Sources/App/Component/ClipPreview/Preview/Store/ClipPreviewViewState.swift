//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

struct ClipPreviewViewState: Equatable {
    let shouldLoadImageSynchronously: Bool

    var itemId: ClipItem.Identity
    var imageId: ImageContainer.Identity
    var imageSize: CGSize

    var source: ClipPreviewView.Source?

    var isLoading: Bool
    var isDismissed: Bool
}
