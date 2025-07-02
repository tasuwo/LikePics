//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class AlbumListCollectionLayout: UICollectionViewFlowLayout {
    // MARK: - UICollectionViewLayout

    override public var collectionViewContentSize: CGSize {
        return super.collectionViewContentSize
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributesList = super.layoutAttributesForElements(in: rect) else {
            return nil
        }

        return layoutAttributesList.map({ currentAttributes in
            switch currentAttributes.representedElementCategory {
            case .cell:
                return self.layoutAttributesForItem(at: currentAttributes.indexPath) ?? currentAttributes

            default:
                return currentAttributes
            }
        })
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else {
            return nil
        }

        if let leftAdjacentAttributes = self.layoutAttributesForLeftAdjacentItem(at: indexPath) {
            layoutAttributes.frame.origin.x = leftAdjacentAttributes.frame.maxX + self.minimumInteritemSpacingForSection(at: indexPath.section)
        } else {
            layoutAttributes.frame.origin.x = self.insetForSection(at: indexPath.section).left
        }

        return layoutAttributes
    }

    // MARK: Methods

    private func layoutAttributesForLeftAdjacentItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard indexPath.item > 0, let layoutAttributes = super.layoutAttributesForItem(at: indexPath) else {
            return nil
        }

        let previousIndexPath = IndexPath(row: indexPath.item - 1, section: indexPath.section)

        if let previousLayoutAttributes = super.layoutAttributesForItem(at: previousIndexPath),
            layoutAttributes.frame.minY >= previousLayoutAttributes.frame.minY,
            layoutAttributes.frame.minY < previousLayoutAttributes.frame.maxY
        {
            return self.layoutAttributesForItem(at: previousIndexPath)
        } else {
            return nil
        }
    }

    private func minimumInteritemSpacingForSection(at sectionIndex: Int) -> CGFloat {
        guard let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else {
            return self.minimumInteritemSpacing
        }
        return delegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: sectionIndex) ?? self.minimumInteritemSpacing
    }

    private func insetForSection(at sectionIndex: Int) -> UIEdgeInsets {
        guard let collectionView = self.collectionView, let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else {
            return self.sectionInset
        }
        return delegate.collectionView?(collectionView, layout: self, insetForSectionAt: sectionIndex) ?? self.sectionInset
    }
}
