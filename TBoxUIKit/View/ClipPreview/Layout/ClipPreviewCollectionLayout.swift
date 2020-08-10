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

    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else {
            return proposedContentOffset
        }

        let visibleRect = CGRect(x: collectionView.contentOffset.x,
                                 y: 0,
                                 width: collectionView.bounds.width,
                                 height: collectionView.bounds.height)

        guard let targetAttributes = layoutAttributesForElements(in: visibleRect)?.sorted(by: { $0.frame.minX < $1.frame.minX }) else {
            return proposedContentOffset
        }

        let nextAttributes: UICollectionViewLayoutAttributes?
        if velocity.x > 0 {
            nextAttributes = targetAttributes.last
        } else if velocity.x < 0 {
            nextAttributes = targetAttributes.first
        } else {
            nextAttributes = self.resolveAttributesNearByCenter(targetAttributes, in: collectionView)
        }

        guard let attributes = nextAttributes else {
            return proposedContentOffset
        }

        return CGPoint(x: attributes.frame.minX,
                       y: collectionView.contentOffset.y)
    }

    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        // TODO: 表示中のセルを再表示する

        guard let collectionView = collectionView else {
            return proposedContentOffset
        }

        let visibleRect = CGRect(x: collectionView.contentOffset.x,
                                 y: 0,
                                 width: collectionView.bounds.width,
                                 height: collectionView.bounds.height)

        guard let targetAttributes = layoutAttributesForElements(in: visibleRect)?.sorted(by: { $0.frame.minX < $1.frame.minX }) else {
            return proposedContentOffset
        }

        let nextAttributes = self.resolveAttributesNearByCenter(targetAttributes, in: collectionView)
        guard let attributes = nextAttributes else {
            return proposedContentOffset
        }

        return CGPoint(x: attributes.frame.minX,
                       y: collectionView.contentOffset.y)
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

    private func resolveAttributesNearByCenter(_ attributesList: [UICollectionViewLayoutAttributes], in collectionView: UICollectionView) -> UICollectionViewLayoutAttributes? {
        struct ExaminedAttributes {
            enum PositionToCenter {
                case intersect
                case left(distance: CGFloat)
                case right(distance: CGFloat)

                var distance: CGFloat {
                    switch self {
                    case .intersect:
                        return 0
                    case let .left(distance: value):
                        return value
                    case let .right(distance: value):
                        return value
                    }
                }
            }

            let attributes: UICollectionViewLayoutAttributes
            let position: PositionToCenter
        }

        let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2

        let examinedAttributeList: [ExaminedAttributes] = attributesList.map { attributes in
            if attributes.frame.maxX < centerX {
                return .init(attributes: attributes, position: .left(distance: centerX - attributes.frame.maxX))
            } else {
                if attributes.frame.minX <= centerX {
                    return .init(attributes: attributes, position: .intersect)
                } else {
                    return .init(attributes: attributes, position: .right(distance: attributes.frame.minX - centerX))
                }
            }
        }

        return examinedAttributeList.min(by: { $0.position.distance < $1.position.distance })?.attributes
    }
}
