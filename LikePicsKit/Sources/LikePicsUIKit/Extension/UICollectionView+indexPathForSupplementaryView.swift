//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UICollectionView {
    public func indexPath(for supplementaryView: UICollectionReusableView?, ofKind kind: String = UICollectionView.elementKindSectionHeader) -> IndexPath? {
        let elements = self.visibleSupplementaryViews(ofKind: kind)
        let indexPaths = self.indexPathsForVisibleSupplementaryElements(ofKind: kind)

        for (element, indexPath) in zip(elements, indexPaths) where element === supplementaryView {
            return indexPath
        }

        return nil
    }
}
