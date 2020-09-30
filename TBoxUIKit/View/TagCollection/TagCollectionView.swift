//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol TagCollectionViewDataSource: AnyObject {
    var isEditing: Bool { get }
}

public class TagCollectionView: UICollectionView {
    public static let cellIdentifier = "Cell"

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
        return { collectionView, indexPath, tag -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: TagCollectionView.cellIdentifier, for: indexPath)
            guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }

            cell.title = tag.name
            cell.displayMode = dataSource.isEditing ? .deletion : .normal

            return cell
        }
    }

    public static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { section, _ -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(36),
                                                  heightDimension: .fractionalHeight(1.0))

            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil, top: nil, trailing: .fixed(8), bottom: nil)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(32))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            group.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(16),
                                                              top: .fixed(8),
                                                              trailing: .fixed(16),
                                                              bottom: nil)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0)

            return section
        }

        return layout
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
