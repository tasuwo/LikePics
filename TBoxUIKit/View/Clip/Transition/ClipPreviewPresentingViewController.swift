//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentingViewController: UIViewController {
    func collectionView(_ animator: ClipPreviewTransitioningAnimator) -> ClipCollectionView
}
