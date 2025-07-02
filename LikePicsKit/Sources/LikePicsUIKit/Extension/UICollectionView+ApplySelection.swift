//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UICollectionView {
    public func applySelection(at indices: [IndexPath]) {
        guard let alreadySelectedItems = self.indexPathsForSelectedItems else {
            indices.forEach { index in
                self.selectItem(at: index, animated: false, scrollPosition: [])
            }
            return
        }

        let selectedItemSet = alreadySelectedItems.reduce(into: Set<IndexPath>()) { result, alreadySelectedItem in
            if indices.contains(alreadySelectedItem) {
                result.insert(alreadySelectedItem)
                return
            }
            self.deselectItem(at: alreadySelectedItem, animated: false)
        }

        Set(indices)
            .subtracting(selectedItemSet)
            .forEach { indexPath in
                self.selectItem(at: indexPath, animated: false, scrollPosition: [])
            }
    }
}
