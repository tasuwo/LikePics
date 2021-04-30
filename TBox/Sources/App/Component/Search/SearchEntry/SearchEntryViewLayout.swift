//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

enum SearchEntryViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case main
    }

    enum Item: Hashable {
        case empty
        case history(ClipSearchHistory)
    }

    enum ElementKind: String {
        case title
    }
}

// MARK: - Layout

extension SearchEntryViewLayout {
    static func createLayout(historyDeletionHandler: @escaping (IndexPath) -> UISwipeActionsConfiguration?) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            return Self.createHistoriesSection(historyDeletionHandler: historyDeletionHandler,
                                               environment: environment)
        }
        return layout
    }

    private static func createHistoriesSection(historyDeletionHandler: @escaping (IndexPath) -> UISwipeActionsConfiguration?,
                                               environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.backgroundColor = .clear
        configuration.trailingSwipeActionsConfigurationProvider = historyDeletionHandler
        let layout = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

        let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(44))
        layout.boundarySupplementaryItems = [
            .init(layoutSize: titleSize, elementKind: ElementKind.title.rawValue, alignment: .top)
        ]

        return layout
    }
}

// MARK: - DataSource

extension SearchEntryViewLayout {
    static func createDataSource(collectionView: UICollectionView) -> DataSource {
        let emptyCellRegistration = configureEmptyCell()
        let historyCellRegistration = configureHistoryCell()
        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(using: emptyCellRegistration, for: indexPath, item: ())
            case let .history(history):
                return collectionView.dequeueConfiguredReusableCell(using: historyCellRegistration, for: indexPath, item: history)
            }
        }

        let headerRegistration = self.configureHistoryHeader()
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch ElementKind(rawValue: elementKind) {
            case .title:
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)

            default:
                return nil
            }
        }

        return dataSource
    }

    private static func configureHistoryHeader() -> UICollectionView.SupplementaryRegistration<SearchEntrySectionHeaderView> {
        return .init(elementKind: ElementKind.title.rawValue) { headerView, _, _ in
            // TODO: 全て削除ボタンを配置する
            headerView.label.text = "最近の検索" // TODO:
        }
    }

    private static func configureEmptyCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Void> {
        return .init { cell, _, _ in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = "最近の検索はありません" // TODO:
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .callout)
            contentConfiguration.textProperties.alignment = .center
            contentConfiguration.textProperties.color = .secondaryLabel
            cell.contentConfiguration = contentConfiguration
        }
    }

    private static func configureHistoryCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, ClipSearchHistory> {
        return .init { cell, _, item in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.image = UIImage(systemName: "clock")
            // TODO: ソート, 表示設定も反映する
            contentConfiguration.text = item.query.displayTitle
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackgroundClient.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }
}
