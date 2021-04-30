//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

enum SearchEntryViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case main
    }

    struct SearchHistoryWrapper: Hashable {
        let isSomeItemsHidden: Bool
        let original: ClipSearchHistory

        var query: ClipSearchQuery { original.query }
    }

    enum Item: Hashable {
        case empty
        case history(SearchHistoryWrapper)
    }

    enum ElementKind: String {
        case historyHeader
        case historyFooter
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
            .init(layoutSize: titleSize, elementKind: ElementKind.historyHeader.rawValue, alignment: .top),
            .init(layoutSize: titleSize, elementKind: ElementKind.historyFooter.rawValue, alignment: .bottom)
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

        let historyHeaderRegistration = self.configureHistoryHeader()
        let historyFooterRegistration = self.configureHistoryFooter()
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch ElementKind(rawValue: elementKind) {
            case .historyHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: historyHeaderRegistration, for: indexPath)

            case .historyFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(using: historyFooterRegistration, for: indexPath)

            default:
                return nil
            }
        }

        return dataSource
    }

    private static func configureHistoryHeader() -> UICollectionView.SupplementaryRegistration<SearchEntrySectionHeaderView> {
        return .init(elementKind: ElementKind.historyHeader.rawValue) { headerView, _, _ in
            // TODO: 全て削除ボタンを配置する
            headerView.label.text = L10n.searchHistorySectionTitle
        }
    }

    private static func configureHistoryFooter() -> UICollectionView.SupplementaryRegistration<SearchEntrySectionFooterView> {
        return .init(elementKind: ElementKind.historyFooter.rawValue) { footerView, _, _ in
            footerView.label.text = L10n.searchHistoryFooterMessage
        }
    }

    private static func configureEmptyCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Void> {
        return .init { cell, _, _ in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = L10n.searchHistoryRowEmptyMessage
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .callout)
            contentConfiguration.textProperties.alignment = .center
            contentConfiguration.textProperties.color = .secondaryLabel
            cell.contentConfiguration = contentConfiguration
        }
    }

    private static func configureHistoryCell() -> UICollectionView.CellRegistration<ClipSearchHistoryListCell, SearchHistoryWrapper> {
        return .init { cell, _, history in
            var contentConfiguration = ClipSearchHistoryContentConfiguration()
            contentConfiguration.queryConfiguration = .init(title: history.query.displayTitle,
                                                            sortName: history.query.sort.displayTitle,
                                                            displaySettingName: history.query.displaySettingDisplayTitle,
                                                            isDisplaySettingHidden: history.isSomeItemsHidden)
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackgroundClient.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }
}
