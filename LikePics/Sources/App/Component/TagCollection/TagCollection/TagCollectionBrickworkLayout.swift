//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class TagCollectionBrickworkLayout: UICollectionViewFlowLayout {
    // MARK: - Privates

    private func layoutAttributesForPreviousAdjacentItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item > 0 else { return nil }

        let previousIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
        guard super.layoutAttributesForItem(at: previousIndexPath) != nil else { return nil }

        return layoutAttributesForItem(at: previousIndexPath)
    }

    private func layoutAttributesForLeftAdjacentItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let previousLayoutAttributes = layoutAttributesForPreviousAdjacentItem(at: indexPath) else { return nil }

        guard let layoutAttributes = super.layoutAttributesForItem(at: indexPath),
              layoutAttributes.frame.minY >= previousLayoutAttributes.frame.minY,
              layoutAttributes.frame.minY < previousLayoutAttributes.frame.maxY
        else {
            return nil
        }

        return previousLayoutAttributes
    }

    private func insetForSection(at sectionIndex: Int) -> UIEdgeInsets {
        guard let collectionView = collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { return sectionInset }
        return delegate.collectionView?(collectionView, layout: self, insetForSectionAt: sectionIndex) ?? sectionInset
    }

    // MARK: - UICollectionViewFlowLayout

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributesList = super.layoutAttributesForElements(in: rect) else { return nil }

        return layoutAttributesList.map {
            switch $0.representedElementCategory {
            case .cell:
                return layoutAttributesForItem(at: $0.indexPath) ?? $0

            default:
                return $0
            }
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }

        if let referenceAttributes = layoutAttributesForLeftAdjacentItem(at: indexPath) {
            layoutAttributes.frame.origin.x = referenceAttributes.frame.maxX + minimumInteritemSpacing
        } else {
            layoutAttributes.frame.origin.x = insetForSection(at: indexPath.section).left
        }

        return layoutAttributes
    }
}
