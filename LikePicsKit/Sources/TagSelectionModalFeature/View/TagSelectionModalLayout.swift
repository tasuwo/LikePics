//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import UIKit

enum TagSelectionModalLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case main
    }

    struct Item: Hashable {
        let tag: Tag
        let displayCount: Bool
    }
}

extension TagSelectionModalLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = TagCollectionBrickworkLayout()
        layout.sectionInset = .init(top: 0, left: 12, bottom: 12, right: 12)
        // 計算コストが高く描画がカクつくので、あえて利用しない
        // layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }
}

extension TagSelectionModalLayout {
    static func configureDataSource(_ collectionView: UICollectionView) -> DataSource {
        let cellRegistration = configureCell()

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    static func configureCell() -> UICollectionView.CellRegistration<TagCollectionViewCell, Item> {
        return .init(cellNib: TagCollectionViewCell.nib) { cell, _, item in
            cell.title = item.tag.name
            cell.displayMode = .checkAtSelect
            cell.visibleCountIfPossible = item.displayCount
            if let clipCount = item.tag.clipCount {
                cell.count = clipCount
            }
            cell.visibleDeleteButton = false
            cell.isHiddenTag = item.tag.isHidden
        }
    }
}
