//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

enum UserInterfaceStyleSelectionViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section {
        case main
    }

    enum Item: CaseIterable {
        case light
        case dark
        case unspecified
    }
}

extension UserInterfaceStyleSelectionViewLayout.Item {
    var title: String {
        switch self {
        case .light:
            return L10n.settingsInterfaceStyleLight

        case .dark:
            return L10n.settingsInterfaceStyleDark

        case .unspecified:
            return L10n.settingsInterfaceStyleUnspecified
        }
    }

    init(_ style: UserInterfaceStyle) {
        switch style {
        case .light:
            self = .light

        case .dark:
            self = .dark

        case .unspecified:
            self = .unspecified
        }
    }

    var style: UserInterfaceStyle {
        switch self {
        case .light:
            return .light

        case .dark:
            return .dark

        case .unspecified:
            return .unspecified
        }
    }
}

extension UserInterfaceStyleSelectionViewLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            createLayoutSection(environment: environment)
        }
        return layout
    }

    private static func createLayoutSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = Asset.Color.backgroundClient.color
        return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
    }
}

extension UserInterfaceStyleSelectionViewLayout {
    static func configureDataSource(collectionView: UICollectionView) -> DataSource {
        let cellRegistration = configureCell()

        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        return dataSource
    }

    private static func configureCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = item.title
            cell.contentConfiguration = contentConfiguration
        }
    }
}