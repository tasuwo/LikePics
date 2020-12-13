//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol TagCollectionViewDataSource: AnyObject {
    func displayMode(_ collectionView: UICollectionView) -> TagCollectionViewCell.DisplayMode
}

public class TagCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"
    public static let interItemSpacing: CGFloat = 8

    // MARK: - Lifecycle

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.registerCell()
        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.registerCell()
        self.setupAppearance()
    }

    // MARK: - Methods

    public static func cellProvider(dataSource: TagCollectionViewDataSource) -> (UICollectionView, IndexPath, Tag) -> UICollectionViewCell? {
        return { [weak dataSource] collectionView, indexPath, tag -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
            guard let dataSource = dataSource else { return dequeuedCell }
            guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }

            cell.title = tag.name
            cell.displayMode = dataSource.displayMode(collectionView)
            if let clipCount = tag.clipCount {
                cell.count = clipCount
            }

            return cell
        }
    }

    public static func createLayoutSection(groupEdgeSpacing: NSCollectionLayoutEdgeSpacing? = nil,
                                           groupContentInsets: NSDirectionalEdgeInsets? = nil) -> NSCollectionLayoutSection
    {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(36),
                                              heightDimension: .estimated(32))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0),
                                                         top: nil,
                                                         trailing: .fixed(Self.interItemSpacing),
                                                         bottom: nil)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(32))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        if let edgeSpacing = groupEdgeSpacing {
            group.edgeSpacing = edgeSpacing
        }

        if let contentInsets = groupContentInsets {
            group.contentInsets = contentInsets
        }

        return NSCollectionLayoutSection(group: group)
    }

    private func registerCell() {
        self.register(TagCollectionViewCell.nib,
                      forCellWithReuseIdentifier: Self.cellIdentifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = true
    }
}
