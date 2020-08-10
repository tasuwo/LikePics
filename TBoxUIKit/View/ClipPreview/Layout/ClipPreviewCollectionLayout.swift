//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewCollectionLayoutDelegate: AnyObject {
    func itemWidth(_ collectionView: UICollectionView) -> CGFloat
    func itemHeight(_ collectionView: UICollectionView) -> CGFloat
}

public class ClipPreviewCollectionLayout: UICollectionViewLayout {
    private static let cellPadding: CGFloat = 10

    public weak var delegate: ClipPreviewCollectionLayoutDelegate?

    private var cache: [UICollectionViewLayoutAttributes] = []

    // MARK: - UICollectionViewFlowLayout

    override public func prepare() {
        self.resetAttributes()
        self.setupAttributes()
    }

    override public var collectionViewContentSize: CGSize {
        guard let collectionView = self.collectionView,
            let delegate = self.delegate
        else {
            return .zero
        }

        let numberOfItems = CGFloat(collectionView.numberOfItems(inSection: 0))
        let totalMargin = numberOfItems > 0 ? (numberOfItems - 1) * Self.cellPadding : 0
        let totalItemWidth = numberOfItems * delegate.itemWidth(collectionView)

        return .init(width: totalItemWidth + totalMargin, height: delegate.itemHeight(collectionView))
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.cache.filter { $0.frame.intersects(rect) }
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cache[indexPath.item]
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    // MARK: - Privates

    private func resetAttributes() {
        self.cache = []
    }

    private func setupAttributes() {
        guard self.cache.isEmpty,
            let collectionView = self.collectionView,
            let delegate = self.delegate
        else {
            return
        }

        var xOffset: CGFloat = 0
        (0 ..< collectionView.numberOfItems(inSection: 0)).forEach {
            let isFirstCell = $0 == 0
            let indexPath = IndexPath(item: $0, section: 0)

            let frame: CGRect = {
                guard !isFirstCell else {
                    return CGRect(x: 0,
                                  y: 0,
                                  width: delegate.itemWidth(collectionView),
                                  height: delegate.itemHeight(collectionView))
                }
                return CGRect(x: xOffset + Self.cellPadding,
                              y: 0,
                              width: delegate.itemWidth(collectionView),
                              height: delegate.itemHeight(collectionView))
            }()

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)

            xOffset = frame.maxX
        }
    }
}
