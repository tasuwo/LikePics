//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipCollectionTransitioningDelegate: NSObject {}

extension ClipCollectionTransitioningDelegate: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning?
    {
        return ClipCollectionTransitionAnimator()
    }
}

public protocol ClipCollectionTransitionAnimatorDataSource: UIViewController {
    func collectionView(_ animator: ClipCollectionTransitionAnimator) -> ClipCollectionView
}
