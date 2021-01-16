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
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.backgroundClient.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

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

    static func createDataSource(collectionView: UICollectionView,
                                 thumbnailLoader: ThumbnailLoader,
                                 buttonCellDelegate: ButtonCellDelegate,
                                 tagCellDelegate: TagCollectionViewCellDelegate) -> DataSource
    {
        let tagAdditionCellRegistration = self.configureTagAdditionCell(delegate: buttonCellDelegate)
        let tagCellRegistration = self.configureTagCell(delegate: tagCellDelegate)
        let itemCellRegistration = self.configureItemCell(thumbnailLoader: thumbnailLoader)

        return DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .item(item):
                return collectionView.dequeueConfiguredReusableCell(using: itemCellRegistration, for: indexPath, item: item)
            }
        }
    }

    private static func configureTagAdditionCell(delegate: ButtonCellDelegate) -> UICollectionView.CellRegistration<ButtonCell, Void> {
        return UICollectionView.CellRegistration<ButtonCell, Void>(cellNib: ButtonCell.nib) { [weak delegate] cell, _, _ in
            cell.title = L10n.clipMergeViewAddTagTitle
            cell.delegate = delegate
        }
    }

    private static func configureTagCell(delegate: TagCollectionViewCellDelegate) -> UICollectionView.CellRegistration<TagCollectionViewCell, Tag> {
        return UICollectionView.CellRegistration<TagCollectionViewCell, Tag>(cellNib: TagCollectionViewCell.nib) { [weak delegate] cell, _, tag in
            cell.title = tag.name
            cell.displayMode = .normal
            cell.visibleCountIfPossible = false
            cell.visibleDeleteButton = true
            cell.delegate = delegate
            cell.isHiddenTag = tag.isHidden
        }
    }

    private static func configureItemCell(thumbnailLoader: ThumbnailLoader) -> UICollectionView.CellRegistration<ClipItemEditListCell, ClipItem> {
        return UICollectionView.CellRegistration<ClipItemEditListCell, ClipItem> { cell, _, item in
            var contentConfiguration = ClipItemEditContentConfiguration()
            contentConfiguration.siteUrl = item.url
            contentConfiguration.isSiteUrlEditable = false
            contentConfiguration.dataSize = Int(item.imageDataSize)
            contentConfiguration.imageWidth = item.imageSize.width
            contentConfiguration.imageHeight = item.imageSize.height
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = .systemBackground
            cell.backgroundConfiguration = backgroundConfiguration

            cell.accessories = [.reorder(displayed: .always)]

            let requestId = UUID().uuidString
            cell.identifier = requestId
            let info = ThumbnailRequest.ThumbnailInfo(id: "clip-merge-\(item.identity.uuidString)",
                                                      size: contentConfiguration.calcThumbnailDisplaySize(),
                                                      scale: cell.traitCollection.displayScale)
            let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
            let request = ThumbnailRequest(requestId: requestId,
                                           originalImageRequest: imageRequest,
                                           thumbnailInfo: info,
                                           isPrefetch: false,
                                           userInfo: nil)
            cell.onReuse = { identifier in
                guard identifier == requestId else { return }
                thumbnailLoader.cancel(request)
            }
            thumbnailLoader.load(request: request, observer: cell)
        }
    }
}
