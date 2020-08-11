//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentingViewControllerProtocol: UIViewController {
    func collectionView(_ animator: UIViewControllerAnimatedTransitioning) -> ClipsCollectionView
}
