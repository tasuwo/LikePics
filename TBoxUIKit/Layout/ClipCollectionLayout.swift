//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipsCollectionLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat
}

public class ClipCollectionLayout: UICollectionViewLayout {
    private static let contentPadding: CGFloat = 8
    private static let cellPadding: CGFloat = 8
    private static let defaultContentHeight: CGFloat = 180

    public weak var delegate: ClipsCollectionLayoutDelegate?

    private var numberOfColumns: Int {
        guard let collectionView = self.collectionView else {
            return 0
        }
        switch collectionView.traitCollection.horizontalSizeClass {
        case .compact:
            return 2

        case .regular:
            return 4

        case .unspecified:
            return 2

        @unknown default:
            return 2
        }
    }

    private var cache: [UICollectionViewLayoutAttributes] = []

    private var contentWidth: CGFloat {
        guard let collectionView = self.collectionView else {
            return 0
        }
        let insets = collectionView.adjustedContentInset
        return collectionView.bounds.width - (insets.left + insets.right) - Self.contentPadding * 2
    }

    private var contentHeight: CGFloat = 0

    // MARK: - UICollectionViewLayout

    override public var collectionViewContentSize: CGSize {
        return CGSize(width: self.contentWidth, height: self.contentHeight)
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.cache.filter { $0.frame.intersects(rect) }
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cache[indexPath.item]
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let collectionView = self.collectionView {
            return collectionView.frame.size != newBounds.size
        }
        return false
    }

    // MARK: - UICollectionViewLayout

    override public func prepare() {
        self.resetAttributes()
        self.setupAttributes()
    }

    // MARK: - Privates

    private func resetAttributes() {
        self.cache = []
        self.contentHeight = 0
    }

    private func setupAttributes() {
        guard cache.isEmpty == true,
              let collectionView = collectionView,
              collectionView.numberOfSections > 0
        else {
            return
        }

        let columnWidth = self.contentWidth / CGFloat(self.numberOfColumns)
        let xOffset = (0 ..< self.numberOfColumns).map { CGFloat($0) * columnWidth + Self.contentPadding }

        setupCellAttributes(collectionView: collectionView,
                            columnWidth: columnWidth,
                            xOffset: xOffset)
    }

    private func setupCellAttributes(collectionView: UICollectionView,
                                     columnWidth: CGFloat,
                                     xOffset: [CGFloat])
    {
        var yOffset = [CGFloat].init(repeating: Self.contentPadding, count: self.numberOfColumns)

        (0 ..< collectionView.numberOfItems(inSection: 0)).forEach {
            let indexPath = IndexPath(item: $0, section: 0)
            let column = $0 % self.numberOfColumns

            let photoHeight = self.delegate?.collectionView(collectionView,
                                                            photoHeightForWidth: columnWidth - Self.cellPadding * 2,
                                                            atIndexPath: indexPath) ?? Self.defaultContentHeight
            let columnHeight = Self.cellPadding * 2 + photoHeight
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: columnHeight)
            let insetFrame = frame.insetBy(dx: Self.cellPadding, dy: Self.cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)

            self.contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] += columnHeight
        }
        self.contentHeight += Self.contentPadding * 2
    }
}
