//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
import UIKit

enum AlbumMultiSelectionModalLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case main
    }

    typealias Item = ListingAlbumTitle
}

// MARK: - Layout

extension AlbumMultiSelectionModalLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .main:
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.background.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

            case .none:
                return nil
            }
        }
        return layout
    }
}

// MARK: - DataSource

extension AlbumMultiSelectionModalLayout {
    private class AlbumCell: UICollectionViewListCell {
        override func updateConfiguration(using state: UICellConfigurationState) {
            super.updateConfiguration(using: state)
            if state.isSelected {
                accessories = [.checkmark()]
            } else {
                accessories = []
            }
        }
    }

    static var font = UIFont.preferredFont(forTextStyle: .callout)

    static func createDataSource(_ collectionView: UICollectionView) -> DataSource {
        let cellRegistration = self.configureCell()

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        return dataSource
    }

    private static func configureCell() -> UICollectionView.CellRegistration<AlbumCell, ListingAlbumTitle> {
        return UICollectionView.CellRegistration<AlbumCell, ListingAlbumTitle> { cell, _, album in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = album.title
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }
}
