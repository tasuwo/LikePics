//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

enum SearchResultViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case tokenCandidates
        case results
    }

    enum Item: Equatable, Hashable {
        case tokenCandidate(SearchToken)
        case result(Clip)
    }
}

// MARK: - Layout

extension SearchResultViewLayout {
    static func createLayout(_ dataSourceProvider: @escaping () -> DataSource?) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            guard let dataSource = dataSourceProvider() else { return nil }

            let identifiers = dataSource.snapshot().sectionIdentifiers
            guard identifiers.count > sectionIndex else { return nil }

            switch identifiers[sectionIndex] {
            case .tokenCandidates:
                return self.createCandidatesSection(environment: environment)

            case .results:
                return self.createSearchResultsSection(environment: environment)
            }
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 16
        layout.configuration = configuration

        return layout
    }

    private static func createCandidatesSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let appearance: UICollectionLayoutListConfiguration.Appearance = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return .plain

            case .regular, .unspecified:
                return .insetGrouped

            @unknown default:
                return .plain
            }
        }()
        var configuration = UICollectionLayoutListConfiguration(appearance: appearance)
        configuration.backgroundColor = Asset.Color.backgroundClient.color
        return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
    }

    private static func createSearchResultsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let count: Int = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return 3

            case .regular, .unspecified:
                return 5

            @unknown default:
                return 5
            }
        }()
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1 / CGFloat(count)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        group.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(8)
        section.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
        section.boundarySupplementaryItems = [
            .init(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        ]

        return section
    }
}

// MARK: - DataSource

extension SearchResultViewLayout {
    static func createDataSource(collectionView: UICollectionView,
                                 thumbnailLoader: ThumbnailLoaderProtocol,
                                 seeAllButtonHandler: @escaping () -> Void) -> DataSource
    {
        let candidateCellRegistration = self.configureCandidateCell()
        let resultCellRegistration = self.configureResultCell(thumbnailLoader: thumbnailLoader)

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case let .tokenCandidate(token):
                return collectionView.dequeueConfiguredReusableCell(using: candidateCellRegistration, for: indexPath, item: token)

            case let .result(clip):
                return collectionView.dequeueConfiguredReusableCell(using: resultCellRegistration, for: indexPath, item: clip)
            }
        }

        let headerRegistration = configureResultHeader(seeAllButtonHandler: seeAllButtonHandler)
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)

            default:
                return nil
            }
        }

        return dataSource
    }

    private static func configureCandidateCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, SearchToken> {
        return .init { cell, _, token in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.attributedText = token.attributedTitle
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackgroundClient.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureResultHeader(seeAllButtonHandler: @escaping () -> Void) -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        return UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { cell, _, _ in
            let seeAllButton = UIButton()
            seeAllButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            seeAllButton.setTitle(L10n.searchResultSeeAllButton, for: .normal)
            seeAllButton.setTitleColor(Asset.Color.likePicsRedClient.color, for: .normal)
            seeAllButton.addAction(.init(handler: { _ in seeAllButtonHandler() }), for: .touchUpInside)

            let seeMoreButtonConfiguration = UICellAccessory.CustomViewConfiguration(customView: seeAllButton,
                                                                                     placement: .trailing(displayed: .always))

            cell.accessories = [
                .customView(configuration: seeMoreButtonConfiguration)
            ]

            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = .clear
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureResultCell(thumbnailLoader: ThumbnailLoaderProtocol) -> UICollectionView.CellRegistration<SearchResultClipCell, Clip> {
        return .init(cellNib: SearchResultClipCell.nib) { [weak thumbnailLoader] cell, _, clip in
            guard let thumbnailLoader = thumbnailLoader,
                  let item = clip.primaryItem
            else {
                cell.imageView.image = nil
                return
            }

            let requestId = UUID().uuidString

            cell.identifier = requestId

            let scale = cell.traitCollection.displayScale
            let request = self.makeRequest(for: item, id: requestId, size: cell.imageView.bounds.size, scale: scale * 2)
            cell.onReuse = { [weak thumbnailLoader] identifier in
                guard identifier == requestId else { return }
                thumbnailLoader?.cancel(request)
            }

            thumbnailLoader.load(request, observer: cell)
        }
    }

    private static func makeRequest(for item: ClipItem, id: String, size: CGSize, scale: CGFloat) -> ThumbnailRequest {
        let info = ThumbnailRequest.ThumbnailInfo(id: "search-result-\(item.identity.uuidString)",
                                                  size: size,
                                                  scale: scale)
        let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
        return ThumbnailRequest(requestId: id,
                                originalImageRequest: imageRequest,
                                thumbnailInfo: info,
                                isPrefetch: false,
                                userInfo: nil)
    }
}