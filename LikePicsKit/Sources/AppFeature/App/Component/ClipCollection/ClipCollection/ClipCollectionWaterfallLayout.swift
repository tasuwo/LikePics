//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipCollectionWaterfallLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, thumbnailHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat
}

class ClipCollectionWaterfallLayout: UICollectionViewLayout {
    private struct Rect: Hashable {
        private let rect: CGRect

        init(_ rect: CGRect) {
            self.rect = rect
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(rect.minX)
            hasher.combine(rect.minY)
            hasher.combine(rect.maxX)
            hasher.combine(rect.maxY)
        }
    }

    private static let contentPadding: CGFloat = 8
    private static let cellPadding: CGFloat = 8
    private static let defaultContentHeight: CGFloat = 180

    weak var delegate: ClipCollectionWaterfallLayoutDelegate?

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

    private var cache: [UICollectionViewLayoutAttributes] = [] {
        didSet {
            self.layoutAttributesForElementsCache = [:]
        }
    }

    private var layoutAttributesForElementsCache: [Rect: [UICollectionViewLayoutAttributes]?] = [:]

    private var contentWidth: CGFloat {
        guard let collectionView = self.collectionView else { return 0 }
        let insets = collectionView.contentInset
        let safeAreaInsets = collectionView.safeAreaInsets
        return collectionView.bounds.width - (insets.left + insets.right + safeAreaInsets.left + safeAreaInsets.right) - Self.contentPadding * 2
    }

    private var contentHeight: CGFloat = 0

    // MARK: - UICollectionViewLayout

    override var collectionViewContentSize: CGSize {
        return CGSize(width: self.contentWidth, height: self.contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if let attributes = layoutAttributesForElementsCache[Rect(rect)] {
            return attributes
        } else {
            let attributes = self.cache.filter { $0.frame.intersects(rect) }
            layoutAttributesForElementsCache[Rect(rect)] = attributes
            return attributes
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cache[indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if let collectionView = self.collectionView {
            return collectionView.frame.size != newBounds.size
        }
        return false
    }

    // MARK: - UICollectionViewLayout

    override func prepare() {
        self.resetAttributes()
        self.setupAttributes()
    }

    // MARK: - Methods

    func calcExpectedThumbnailWidth(originalSize: CGSize) -> CGSize {
        let columnWidth = self.contentWidth / CGFloat(self.numberOfColumns)
        let photoWidth = columnWidth - Self.cellPadding * 2

        if originalSize.width < originalSize.height {
            return .init(width: photoWidth,
                         height: photoWidth * (originalSize.height / originalSize.width))
        } else {
            return .init(width: photoWidth * (originalSize.width / originalSize.height),
                         height: photoWidth)
        }
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
        setupCellAttributes(collectionView: collectionView)
    }

    private func setupCellAttributes(collectionView: UICollectionView) {
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        let xOffset = (0 ..< numberOfColumns).map { CGFloat($0) * columnWidth + Self.contentPadding + collectionView.safeAreaInsets.left }
        var yOffset = [CGFloat].init(repeating: Self.contentPadding, count: numberOfColumns)

        (0 ..< collectionView.numberOfItems(inSection: 0)).forEach {
            let indexPath = IndexPath(item: $0, section: 0)

            // 最も低いcolumnに追加する
            let column = yOffset.enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? $0 % numberOfColumns

            let thumbnailHeight = self.delegate?.collectionView(collectionView,
                                                                thumbnailHeightForWidth: columnWidth - Self.cellPadding * 2,
                                                                atIndexPath: indexPath) ?? Self.defaultContentHeight
            let itemHeight = Self.cellPadding * 2 + thumbnailHeight

            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: itemHeight)
            let insetFrame = frame.insetBy(dx: Self.cellPadding, dy: Self.cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)

            self.contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] += itemHeight
        }
        self.contentHeight += Self.contentPadding * 2
    }
}
