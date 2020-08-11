//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentedViewControllerProtocol: UIViewController {
    func collectionView(_ animator: UIViewControllerAnimatedTransitioning) -> ClipPreviewCollectionView
}
