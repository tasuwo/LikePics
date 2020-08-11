//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentingAnimatorDataSource {
    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipsCollectionViewCell?
}
