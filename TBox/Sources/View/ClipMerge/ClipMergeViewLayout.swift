//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

enum ClipMergeViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case tag
        case clip
    }

    enum Item: Hashable {
        case tagAddition
        case tag(Tag)
        case item(ClipItem)

        var identifier: String {
            switch self {
            case .tagAddition:
                return "tag-addition"

            case let .tag(tag):
                return tag.id.uuidString

            case let .item(clipItem):
                return clipItem.id.uuidString
            }
        }
    }
}

// MARK: - Compositional Layout

extension ClipMergeViewLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .clip:
                return self.createClipsLayoutSection(environment: environment)

            case .none:
                return nil
            }
        }
        return layout
    }

    private static func createTagsLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(36),
                                              heightDimension: .estimated(32))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(32))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(8)
        section.contentInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20)

        return section
    }

    private static func createClipsLayoutSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let count: CGFloat = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return 2

            case .regular, .unspecified:
                return 4

            @unknown default:
                return 4
            }
        }()
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1.0 / count))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: Int(count))
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(16)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        return section
    }
}

// MARK: - DataSource

extension ClipMergeViewLayout {
    static func createSnapshot(tags: [Tag], items: [ClipItem]) -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Item.tagAddition] + tags.map({ Item.tag($0) }))
        snapshot.appendSections([.clip])
        snapshot.appendItems(items.map({ Item.item($0) }))
        return snapshot
    }

    static func createItems(tags: [Tag], items: [ClipItem]) -> [Item] {
        return [Item.tagAddition]
            + tags.map({ Item.tag($0) })
            + items.map({ Item.item($0) })
    }

    static func configureDataSource(collectionView: UICollectionView,
                                    thumbnailLoader: ThumbnailLoader,
                                    buttonCellDelegate: ButtonCellDelegate,
                                    tagCellDelegate: TagCollectionViewCellDelegate) -> DataSource
    {
        let tagAdditionCellRegistration = UICollectionView.CellRegistration<ButtonCell, Void>(cellNib: ButtonCell.nib) { [weak buttonCellDelegate] cell, _, _ in
            cell.title = L10n.clipMergeViewAddTagTitle
            cell.delegate = buttonCellDelegate
        }

        let tagCellRegistration = UICollectionView.CellRegistration<TagCollectionViewCell, Tag>(cellNib: TagCollectionViewCell.nib) { [weak tagCellDelegate] cell, _, tag in
            cell.title = tag.name
            cell.displayMode = .normal
            cell.visibleCountIfPossible = false
            cell.visibleDeleteButton = true
            cell.delegate = tagCellDelegate
            cell.isHiddenTag = tag.isHidden
        }

        let imageCellRegistration = UICollectionView.CellRegistration<ClipMergeImageCell, ClipItem>(cellNib: ClipMergeImageCell.nib) { [weak thumbnailLoader] cell, _, clipItem in
            let requestId = UUID().uuidString
            cell.identifier = requestId
            cell.thumbnail = nil

            let info = ThumbnailRequest.ThumbnailInfo(id: "clip-merge-\(clipItem.identity.uuidString)",
                                                      size: cell.thumbnailDisplaySize,
                                                      scale: cell.traitCollection.displayScale)
            let imageRequest = ImageDataLoadRequest(imageId: clipItem.imageId)
            let request = ThumbnailRequest(requestId: requestId,
                                           originalImageRequest: imageRequest,
                                           thumbnailInfo: info)
            thumbnailLoader?.load(request: request, observer: cell)
            cell.onReuse = { identifier in
                guard identifier == requestId else { return }
                thumbnailLoader?.cancel(request)
            }
        }

        return DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .item(item):
                return collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: item)
            }
        }
    }
}
