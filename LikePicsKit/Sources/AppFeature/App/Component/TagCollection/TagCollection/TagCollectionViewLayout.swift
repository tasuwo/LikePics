//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import UIKit

enum TagCollectionViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case uncategorized
        case main
    }

    enum Item: Hashable {
        struct ListingTag: Hashable {
            let tag: Tag
            let displayCount: Bool
        }

        case uncategorized
        case tag(ListingTag)

        var isTag: Bool {
            switch self {
            case .tag:
                return true

            case .uncategorized:
                return false
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.uncategorized, .uncategorized):
                return true

            case let (.tag(ltag), .tag(rtag)):
                // isHidden は差分更新に含めないよう、比較から外す
                return ltag.tag.id == rtag.tag.id
                    && ltag.tag.name == rtag.tag.name
                    && ltag.tag.clipCount == rtag.tag.clipCount
                    && ltag.displayCount == rtag.displayCount

            default:
                return false
            }
        }
    }
}

// MARK: - Layout

extension TagCollectionViewLayout {
    static func createLayout(delegate: NewTagCollectionBrickworkLayoutDelegate) -> UICollectionViewLayout {
        let layout = NewTagCollectionBrickworkLayout()
        layout.delegate = delegate
        // 計算コストが高く描画がカクつくので、あえて利用しない
        // layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }
}

// MARK: - DataSource

extension TagCollectionViewLayout {
    static func apply(items: [Item], to dataSource: DataSource, in collectionView: UICollectionView) {
        var snapshot = Snapshot()

        snapshot.appendSections([.uncategorized])
        if items.first == .uncategorized {
            snapshot.appendItems([.uncategorized])
        }

        snapshot.appendSections([.main])
        snapshot.appendItems(items.filter { $0.isTag })

        dataSource.apply(snapshot, animatingDifferences: true) { [weak collectionView] in
            var shouldInvalidateLayout = false
            collectionView?.indexPathsForVisibleItems.forEach { indexPath in
                guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
                guard let cell = collectionView?.cellForItem(at: indexPath) as? TagCollectionViewCell else { return }
                guard case let .tag(tag) = item else { return }
                if tag.displayCount != cell.visibleCountIfPossible {
                    cell.visibleCountIfPossible = tag.displayCount
                    shouldInvalidateLayout = true
                }
                if tag.tag.isHidden != cell.isHiddenTag {
                    cell.isHiddenTag = tag.tag.isHidden
                }
            }
            if shouldInvalidateLayout {
                collectionView?.collectionViewLayout.invalidateLayout()
            }
        }
    }

    private static func configureUncategorizedCell(delegate: UncategorizedCellDelegate) -> UICollectionView.CellRegistration<UncategorizedCell, Void> {
        return .init(cellNib: UncategorizedCell.nib) { [weak delegate] cell, _, _ in
            cell.delegate = delegate
        }
    }

    private static func configureTagCell() -> UICollectionView.CellRegistration<TagCollectionViewCell, Item.ListingTag> {
        return .init(cellNib: TagCollectionViewCell.nib) { cell, _, item in
            cell.title = item.tag.name
            cell.displayMode = .normal
            cell.visibleCountIfPossible = item.displayCount
            if let clipCount = item.tag.clipCount {
                cell.count = clipCount
            }
            cell.visibleDeleteButton = false
            cell.isHiddenTag = item.tag.isHidden
        }
    }

    static func configureDataSource(collectionView: UICollectionView,
                                    uncategorizedCellDelegate: UncategorizedCellDelegate) -> DataSource
    {
        let tagCellRegistration = self.configureTagCell()
        let uncategorizedCellRegistration = self.configureUncategorizedCell(delegate: uncategorizedCellDelegate)

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .uncategorized:
                return collectionView.dequeueConfiguredReusableCell(using: uncategorizedCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)
            }
        }
    }
}
