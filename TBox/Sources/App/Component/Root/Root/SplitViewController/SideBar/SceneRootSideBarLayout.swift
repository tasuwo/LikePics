//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import TBoxUIKit
import UIKit

enum SceneRootSideBarLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case main
    }

    typealias Item = SceneRoot.SideBarItem
}

// MARK: - Layout

extension SceneRootSideBarLayout {
    static func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.backgroundColor = Asset.Color.background.color
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
    }
}

// MARK: - DataSource

extension SceneRootSideBarLayout {
    static func configureDataSource(collectionView: UICollectionView) -> DataSource {
        let cellRegistration = configureCell(collectionView: collectionView)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }

    private static func configureCell(collectionView: UICollectionView) -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        return .init { cell, _, item in
            var contentConfiguration = UIListContentConfiguration.sidebarCell()
            contentConfiguration.image = item.image
            contentConfiguration.text = item.title
            cell.contentConfiguration = contentConfiguration
        }
    }
}
