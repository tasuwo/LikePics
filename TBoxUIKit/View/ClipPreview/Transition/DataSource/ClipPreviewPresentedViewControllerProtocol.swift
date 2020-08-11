//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentedAnimatorDataSource {
    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewPageView?
}
