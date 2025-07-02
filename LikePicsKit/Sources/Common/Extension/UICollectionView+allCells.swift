//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)

import Foundation
import UIKit

extension UICollectionView {
    public var allCells: [UICollectionViewCell] {
        guard numberOfSections > 0 else { return [] }

        var cells = [UICollectionViewCell]()
        for section in 0...numberOfSections - 1 {
            guard numberOfItems(inSection: section) > 0 else {
                continue
            }

            for row in 0...numberOfItems(inSection: section) - 1 {
                if let cell = cellForItem(at: IndexPath(row: row, section: section)) {
                    cells.append(cell)
                }
            }
        }

        return cells
    }
}

#endif
