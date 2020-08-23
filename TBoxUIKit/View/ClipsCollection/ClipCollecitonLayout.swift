//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipsCollectionLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat
}

public class ClipCollectionLayout: UICollectionViewLayout {
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

    private static let cellPadding: CGFloat = 10

    private var cache: [UICollectionViewLayoutAttributes] = []

    private static let defaultContentHeight: CGFloat = 180
    private var contentWidth: CGFloat {
        guard let collectionView = self.collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    private var contentHeight: CGFloat = 0

    // MARK: - UICollectionViewLayout

    override public func prepare() {
        self.resetAttributes()
        self.setupAttributes()
    }

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

    // MARK: - Privates

    private func resetAttributes() {
        self.cache = []
        self.contentHeight = 0
    }

    private func setupAttributes() {
        guard self.cache.isEmpty, let collectionView = self.collectionView else { return }

        let columnWidth = self.contentWidth / CGFloat(self.numberOfColumns)
        let xOffset = (0 ..< self.numberOfColumns).map { CGFloat($0) * columnWidth }

        let headerViewHeight = self.setupHeaderAttributes()
        setupCellAttributes(collectionView: collectionView,
                            columnWidth: columnWidth,
                            xOffset: xOffset,
                            headerViewHeight: headerViewHeight)
    }

    private func setupHeaderAttributes() -> CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let indexPath = IndexPath(item: 0, section: 0)
        let headerViewAttribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, with: indexPath)
        let headerViewHeight = self.delegate?.collectionView(collectionView, heightForHeaderAtIndexPath: indexPath) ?? 0
        headerViewAttribute.frame = .init(origin: .zero, size: .init(width: collectionView.bounds.size.width, height: headerViewHeight))
        self.cache.append(headerViewAttribute)
        self.contentHeight = max(contentHeight, headerViewAttribute.frame.maxY)

        return headerViewHeight
    }

    private func setupCellAttributes(collectionView: UICollectionView,
                                     columnWidth: CGFloat,
                                     xOffset: [CGFloat],
                                     headerViewHeight: CGFloat)
    {
        var yOffset = [CGFloat].init(repeating: headerViewHeight, count: self.numberOfColumns)

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
    }
}
