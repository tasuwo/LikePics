//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentedViewController: UIViewController {
    func collectionView(_ animator: UIViewControllerAnimatedTransitioning) -> ClipPreviewCollectionView
}
