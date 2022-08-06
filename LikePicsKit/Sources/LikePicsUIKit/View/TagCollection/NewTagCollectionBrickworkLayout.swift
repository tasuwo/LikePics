//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol NewTagCollectionBrickworkLayoutDelegate: AnyObject {
    func heightOfUncategorizedCell(_ collectionView: UICollectionView) -> CGFloat
    func heightOfTagCell(_ collectionView: UICollectionView) -> CGFloat
    func collectionView(_ collectionView: UICollectionView, widthAtIndexPath indexPath: IndexPath) -> CGFloat
}

public class NewTagCollectionBrickworkLayout: UICollectionViewLayout {
    struct Cache {
        let uncategorizedItemHeight: CGFloat
        let tagItemHeight: CGFloat
        var numberOfRows = 1
        var indicesByRow: [Int: Set<IndexPath>] = [:]
        var attributesByIndex: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    }

    private static let contentPadding: CGFloat = 8
    private static let interSectionSpacing: CGFloat = 8
    private static let widthPadding: CGFloat = 4
    private static let heightPadding: CGFloat = 6

    private var contentWidth: CGFloat {
        guard let collectionView = self.collectionView else { return 0 }
        let contentInsetWidth = collectionView.contentInset.left + collectionView.contentInset.right
        let safeAreaInsetWidth = collectionView.safeAreaInsets.left + collectionView.safeAreaInsets.right
        return collectionView.bounds.width - (contentInsetWidth + safeAreaInsetWidth)
    }

    private var contentHeight: CGFloat = 0

    private var cache: Cache?

    public weak var delegate: NewTagCollectionBrickworkLayoutDelegate?

    // MARK: - UICollectionViewLayout

    override public var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let cache = cache else { return nil }

        let startRow: Int = rect.minY <= (cache.uncategorizedItemHeight + Self.interSectionSpacing)
            ? 1
            : 1 + Int(ceil((rect.minY - (cache.uncategorizedItemHeight + Self.interSectionSpacing)) / cache.tagItemHeight))
        let endRow: Int = rect.maxY <= (cache.uncategorizedItemHeight + Self.interSectionSpacing)
            ? 1
            : 1 + Int(ceil((rect.maxY - (cache.uncategorizedItemHeight + Self.interSectionSpacing)) / cache.tagItemHeight))

        return (startRow ... endRow)
            .compactMap { cache.indicesByRow[$0] }
            .reduce(into: Set<IndexPath>(), { $0 = $0.union($1) })
            .compactMap { cache.attributesByIndex[$0] }
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache?.attributesByIndex[indexPath]
    }

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let collectionView = collectionView {
            return collectionView.frame.size != newBounds.size
        }
        return false
    }

    override public func prepare() {
        resetAttributes()
        setupAttributes()
    }
}

extension NewTagCollectionBrickworkLayout {
    private func resetAttributes() {
        cache = nil
        contentHeight = 0
    }

    private func setupAttributes() {
        guard cache == nil,
              let delegate = delegate,
              let collectionView = collectionView,
              collectionView.numberOfSections > 0
        else {
            return
        }
        setupCellAttributes(collectionView: collectionView, delegate: delegate)
    }

    private func setupCellAttributes(collectionView: UICollectionView, delegate: NewTagCollectionBrickworkLayoutDelegate) {
        let initialXOffset = collectionView.contentInset.right + collectionView.safeAreaInsets.right + Self.contentPadding
        let maxXOffset = initialXOffset + (contentWidth - Self.contentPadding * 2)
        let initialYOffset = collectionView.contentInset.top + collectionView.safeAreaInsets.top

        var currentXOffset = initialXOffset
        var currentYOffset = initialYOffset

        let uncategorizedItemHeight = delegate.heightOfUncategorizedCell(collectionView)
        let tagCellHeight = delegate.heightOfTagCell(collectionView)
        let tagItemHeight = tagCellHeight + Self.heightPadding * 2
        var cache = Cache(uncategorizedItemHeight: uncategorizedItemHeight,
                          tagItemHeight: tagItemHeight)

        (0 ..< collectionView.numberOfItems(inSection: 0)).forEach { row in
            let indexPath = IndexPath(row: row, section: 0)

            let frame = CGRect(x: Self.widthPadding + initialXOffset,
                               y: initialYOffset,
                               width: contentWidth - Self.contentPadding * 2 - Self.widthPadding * 2,
                               height: uncategorizedItemHeight)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame

            cache.indicesByRow[cache.numberOfRows] =
                (cache.indicesByRow[cache.numberOfRows] ?? .init()).union(Set([indexPath]))
            cache.attributesByIndex[indexPath] = attributes

            currentXOffset = initialXOffset
            currentYOffset += uncategorizedItemHeight
            cache.numberOfRows += 1
        }

        currentYOffset += Self.interSectionSpacing

        (0 ..< collectionView.numberOfItems(inSection: 1)).forEach { row in
            let indexPath = IndexPath(row: row, section: 1)

            let tagCellWidth = delegate.collectionView(collectionView, widthAtIndexPath: indexPath)
            let tagItemWidth = tagCellWidth + Self.widthPadding * 2

            if currentXOffset + tagItemWidth > maxXOffset {
                currentXOffset = initialXOffset
                currentYOffset += tagItemHeight
                cache.numberOfRows += 1
            }

            let frame = CGRect(x: Self.widthPadding + currentXOffset,
                               y: Self.heightPadding + currentYOffset,
                               width: tagCellWidth,
                               height: tagCellHeight)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame

            cache.indicesByRow[cache.numberOfRows] =
                (cache.indicesByRow[cache.numberOfRows] ?? .init()).union(Set([indexPath]))
            cache.attributesByIndex[indexPath] = attributes

            currentXOffset += tagItemWidth
        }

        self.cache = cache
        contentHeight = currentYOffset + tagItemHeight + Self.contentPadding
    }
}
