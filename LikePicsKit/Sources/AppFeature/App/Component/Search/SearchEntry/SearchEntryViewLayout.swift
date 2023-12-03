//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
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
        let original: Domain.ClipSearchHistory

        var query: ClipSearchQuery { original.query }
    }

    enum Item: Hashable {
        case empty
        case historyHeader(enabledRemoveAllButton: Bool)
        case history(SearchHistoryWrapper)
    }

    enum ElementKind: String {
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
        configuration.showsSeparators = false
        let layout = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

        let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(44))
        layout.boundarySupplementaryItems = [
            .init(layoutSize: titleSize, elementKind: ElementKind.historyFooter.rawValue, alignment: .bottom)
        ]

        return layout
    }
}

// MARK: - DataSource

extension SearchEntryViewLayout {
    static func createDataSource(collectionView: UICollectionView,
                                 removeAllHistoriesHandler: @escaping () -> Void) -> DataSource
    {
        let emptyCellRegistration = configureEmptyCell()
        let historyHeaderRegistration = self.configureHistoryHeader(removeAllHistoriesHandler: removeAllHistoriesHandler)
        let historyCellRegistration = configureHistoryCell()
        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .empty:
                return collectionView.dequeueConfiguredReusableCell(using: emptyCellRegistration, for: indexPath, item: ())

            case let .historyHeader(enabledRemoveAllButton: isEnabled):
                return collectionView.dequeueConfiguredReusableCell(using: historyHeaderRegistration, for: indexPath, item: isEnabled)

            case let .history(history):
                return collectionView.dequeueConfiguredReusableCell(using: historyCellRegistration, for: indexPath, item: history)
            }
        }

        let historyFooterRegistration = self.configureHistoryFooter()
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch ElementKind(rawValue: elementKind) {
            case .historyFooter:
                return collectionView.dequeueConfiguredReusableSupplementary(using: historyFooterRegistration, for: indexPath)

            default:
                return nil
            }
        }

        return dataSource
    }

    private static func configureHistoryFooter() -> UICollectionView.SupplementaryRegistration<SearchEntrySectionFooterView> {
        return .init(elementKind: ElementKind.historyFooter.rawValue) { footerView, _, _ in
            footerView.title = L10n.searchHistoryFooterMessage
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

    private static func configureHistoryHeader(removeAllHistoriesHandler: @escaping () -> Void) -> UICollectionView.CellRegistration<ClipSearchHistoryHeaderCell, Bool> {
        return .init { cell, _, isEnabled in
            cell.removeAllHistoriesHandler = removeAllHistoriesHandler
            cell.isRemoveAllButtonEnabled = isEnabled

            var backgroundConfiguration = UIBackgroundConfiguration.listPlainHeaderFooter()
            backgroundConfiguration.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureHistoryCell() -> UICollectionView.CellRegistration<ClipSearchHistoryContentCell, SearchHistoryWrapper> {
        return .init { cell, _, history in
            cell.searchHistory = .init(title: history.query.displayTitle,
                                       sortName: history.query.sort.displayTitle,
                                       displaySettingName: history.query.displaySettingDisplayTitle,
                                       isDisplaySettingHidden: history.isSomeItemsHidden)

            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }
}
