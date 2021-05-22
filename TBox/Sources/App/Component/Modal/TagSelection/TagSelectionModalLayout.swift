//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

enum TagSelectionModalLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case main
    }

    typealias Item = Tag
}

extension TagSelectionModalLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = TagCollectionBrickworkLayout()
        layout.sectionInset = .init(top: 0, left: 12, bottom: 0, right: 12)
        layout.sectionInsetReference = .fromSafeArea
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
            cell.title = item.name
            cell.displayMode = .checkAtSelect
            cell.visibleCountIfPossible = true
            if let clipCount = item.clipCount {
                cell.count = clipCount
            }
            cell.visibleDeleteButton = false
            cell.isHiddenTag = item.isHidden
        }
    }
}
