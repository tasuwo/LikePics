//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
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
        case tokenCandidate(ClipSearchToken)
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
        configuration.backgroundColor = .clear
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
        group.interItemSpacing = .fixed(12)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(12)
        section.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
        section.boundarySupplementaryItems = [
            .init(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        ]

        return section
    }
}

// MARK: - DataSource

extension SearchResultViewLayout {
    static func createDataSource(_ collectionView: UICollectionView,
                                 _ thumbnailPipeline: Pipeline,
                                 _ imageQueryService: ImageQueryServiceProtocol,
                                 seeAllButtonHandler: @escaping () -> Void) -> DataSource
    {
        let candidateCellRegistration = self.configureCandidateCell()
        let resultCellRegistration = self.configureResultCell(thumbnailPipeline: thumbnailPipeline,
                                                              imageQueryService: imageQueryService)

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

    private static func configureCandidateCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, ClipSearchToken> {
        return .init { cell, _, token in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.attributedText = token.attributedTitle
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureResultHeader(seeAllButtonHandler: @escaping () -> Void) -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        return UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { cell, _, _ in
            let seeAllButton = UIButton(type: .system)
            seeAllButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            seeAllButton.titleLabel?.adjustsFontForContentSizeCategory = true
            seeAllButton.setTitle(L10n.searchResultSeeAllButton, for: .normal)
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

    private static func configureResultCell(thumbnailPipeline: Pipeline,
                                            imageQueryService: ImageQueryServiceProtocol) -> UICollectionView.CellRegistration<SearchResultClipCell, Clip>
    {
        return .init(cellNib: SearchResultClipCell.nib) { [weak thumbnailPipeline, weak imageQueryService] cell, _, clip in
            guard let pipeline = thumbnailPipeline,
                  let imageQueryService = imageQueryService,
                  let item = clip.primaryItem
            else {
                cell.imageView.image = nil
                return
            }

            let scale = cell.traitCollection.displayScale
            let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
            let provider = ImageDataProvider(imageId: item.imageId,
                                             cacheKey: "search-result-\(item.identity.uuidString)",
                                             imageQueryService: imageQueryService)
            let request = ImageRequest(source: .provider(provider),
                                       resize: .init(size: size, scale: scale))
            loadImage(request, with: pipeline, on: cell)
        }
    }
}
