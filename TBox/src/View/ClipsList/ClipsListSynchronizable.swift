//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListSynchronizableDelegate: AnyObject {
    func clipsListSynchronizable(_ synchronizable: ClipsListSynchronizable, updatedClipsTo clips: [Clip])

    func clipsListSynchronizable(_ synchronizable: ClipsListSynchronizable, updatedContentOffset offset: CGPoint)
}

protocol ClipsListSynchronizable {
    var delegate: ClipsListSynchronizableDelegate? { get }
    var collectionView: ClipsCollectionView! { get }
}

extension ClipsListSynchronizable where Self: UIScrollViewDelegate {
    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ synchronizable: Self, _ scrollView: UIScrollView) {
        self.delegate?.clipsListSynchronizable(self, updatedContentOffset: self.collectionView?.contentOffset ?? .zero)
    }
}
