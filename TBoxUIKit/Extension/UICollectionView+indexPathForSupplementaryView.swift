//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UICollectionView {
    func indexPath(for supplementaryView: UICollectionReusableView?, ofKind kind: String = UICollectionView.elementKindSectionHeader) -> IndexPath? {
        let elements = self.visibleSupplementaryViews(ofKind: kind)
        let indexPaths = self.indexPathsForVisibleSupplementaryElements(ofKind: kind)

        for (element, indexPath) in zip(elements, indexPaths) {
            if element === supplementaryView {
                return indexPath
            }
        }

        return nil
    }
}
