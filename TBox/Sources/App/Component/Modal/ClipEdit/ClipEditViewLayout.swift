//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import TBoxUIKit
import UIKit

protocol ClipEditViewDelegate: AnyObject {
    func trailingSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration?
    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool)
    func didTapTagAdditionButton(_ cell: UICollectionViewCell)
    func didTapTagDeletionButton(_ cell: UICollectionViewCell)
    func didTapSiteUrl(_ sender: UIView, url: URL?)
    func didTapSiteUrlEditButton(_ sender: UIView, url: URL?)
    func didTapSelectionButton()
    func didTapCancelSelectionButton()
    func didTapEditSiteUrlsForSelectionButton()
}

enum ClipEditViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    typealias SectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>

    enum Section: Int, CaseIterable {
        case tag
        case meta
        case clipItem
        case footer
    }

    enum Item: Equatable, Hashable {
        case tagAddition
        case tag(Tag)
        case meta(Info)
        case clipItem(ClipItem)
        case deleteClip

        var canReorder: Bool {
            switch self {
            case .clipItem:
                return true

            default:
                return false
            }
        }
    }

    struct Info: Equatable, Hashable {
        enum Accessory: Equatable, Hashable {
            case label(title: String)
            case `switch`(isOn: Bool)
        }

        let title: String
        let accessory: Accessory
    }

    struct ClipItem: Equatable, Hashable {
        let itemId: UUID
        let imageId: UUID
        let imageUrl: URL?
        let siteUrl: URL?
        let dataSize: Double
        let imageHeight: Double
        let imageWidth: Double

        var imageSize: CGSize {
            return .init(width: CGFloat(imageWidth), height: CGFloat(imageHeight))
        }
    }
}

// MARK: - Layout

extension ClipEditViewLayout {
    static func createLayout(delegate: ClipEditViewDelegate) -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .meta:
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.backgroundClient.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

            case .clipItem:
                return self.createItemLayoutSection(delegate: delegate, environment: environment)

            case .footer:
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
        section.contentInsets = .init(top: 30, leading: 20, bottom: 10, trailing: 20)

        return section
    }

    private static func createItemLayoutSection(delegate: ClipEditViewDelegate, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.backgroundColor = Asset.Color.backgroundClient.color
        configuration.trailingSwipeActionsConfigurationProvider = { [weak delegate] indexPath in
            return delegate?.trailingSwipeAction(indexPath: indexPath)
        }

        let layout = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        let lastInsets = layout.contentInsets
        layout.contentInsets = .init(top: 0,
                                     leading: lastInsets.leading,
                                     bottom: lastInsets.bottom,
                                     trailing: lastInsets.trailing)

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(50))
        layout.boundarySupplementaryItems = [
            .init(layoutSize: size, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        ]

        return layout
    }
}

// MARK: - DataSource

extension ClipEditViewLayout {
    class Proxy {
        weak var delegate: ClipEditViewDelegate?
        weak var interactionDelegate: UIContextMenuInteractionDelegate?
    }

    static func createDataSource(collectionView: UICollectionView,
                                 thumbnailLoader: ThumbnailLoaderProtocol) -> (DataSource, Proxy)
    {
        let proxy = Proxy()

        let tagAdditionCellRegistration = self.configureTagAdditionCell(delegate: proxy)
        let tagCellRegistration = self.configureTagCell(delegate: proxy)
        let metaCellRegistration = self.configureMetaCell(proxy: proxy)
        let itemCellRegistration = self.configureItemCell(proxy: proxy, thumbnailLoader: thumbnailLoader)
        let deleteCellRegistration = self.configureDeleteClipCell()

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .meta(meta):
                return collectionView.dequeueConfiguredReusableCell(using: metaCellRegistration, for: indexPath, item: meta)

            case let .clipItem(clipItem):
                return collectionView.dequeueConfiguredReusableCell(using: itemCellRegistration, for: indexPath, item: clipItem)

            case .deleteClip:
                return collectionView.dequeueConfiguredReusableCell(using: deleteCellRegistration, for: indexPath, item: ())
            }
        }

        let itemHeaderRegistration = self.configureItemHeader(proxy: proxy)

        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch elementKind {
            case UICollectionView.elementKindSectionHeader:
                return collectionView.dequeueConfiguredReusableSupplementary(using: itemHeaderRegistration, for: indexPath)

            default:
                return nil
            }
        }

        return (dataSource, proxy)
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

    private static func configureMetaCell(proxy: Proxy) -> UICollectionView.CellRegistration<UICollectionViewListCell, Info> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Info> { cell, indexPath, info in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = info.title
            cell.contentConfiguration = contentConfiguration

            switch info.accessory {
            case let .label(title: title):
                cell.accessories = [.label(text: title)]

            case let .switch(isOn: isOn):
                // swiftlint:disable:next identifier_name
                let sw = UISwitch()
                sw.isOn = isOn
                sw.addAction(.init(handler: { [weak proxy] action in
                    // swiftlint:disable:next identifier_name
                    guard let sw = action.sender as? UISwitch else { return }
                    proxy?.didSwitchHiding(cell, at: indexPath, isOn: sw.isOn)
                }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: sw,
                                                                            placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]
            }

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackgroundClient.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureDeleteClipCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, Void> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Void> { cell, _, _ in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = L10n.clipEditViewDeleteClipTitle
            contentConfiguration.textProperties.alignment = .center
            contentConfiguration.textProperties.color = UIColor.systemRed
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackgroundClient.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureItemCell(proxy: Proxy,
                                          thumbnailLoader: ThumbnailLoaderProtocol) -> UICollectionView.CellRegistration<ClipItemEditListCell, ClipItem>
    {
        return UICollectionView.CellRegistration<ClipItemEditListCell, ClipItem> { [weak proxy, weak thumbnailLoader] cell, _, item in
            var contentConfiguration = ClipItemEditContentConfiguration()
            contentConfiguration.siteUrl = item.siteUrl
            contentConfiguration.dataSize = Int(item.dataSize)
            contentConfiguration.imageWidth = item.imageWidth
            contentConfiguration.imageHeight = item.imageHeight
            contentConfiguration.delegate = proxy
            contentConfiguration.interactionDelegate = proxy?.interactionDelegate
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackgroundClient.color
            cell.backgroundConfiguration = backgroundConfiguration

            cell.accessories = [
                .multiselect(displayed: .whenEditing),
                .reorder(displayed: .whenNotEditing)
            ]

            let requestId = UUID().uuidString
            cell.identifier = requestId
            let size = cell.calcThumbnailImageSize(originalSize: item.imageSize)
            let info = ThumbnailConfig(cacheKey: "clip-edit-list-\(item.itemId.uuidString)",
                                       size: size,
                                       scale: cell.traitCollection.displayScale)
            let imageRequest = ImageDataLoadRequest(imageId: item.imageId)
            let request = ThumbnailRequest(requestId: requestId,
                                           originalImageRequest: imageRequest,
                                           config: info,
                                           isPrefetch: false,
                                           userInfo: nil)
            cell.onReuse = { identifier in
                guard identifier == requestId else { return }
                thumbnailLoader?.cancel(request)
            }
            thumbnailLoader?.load(request, observer: cell)
        }
    }

    private static func configureItemHeader(proxy: Proxy) -> UICollectionView.SupplementaryRegistration<UICollectionViewListCell> {
        return UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { headerView, _, _ in
            let selectButton = UIButton()
            selectButton.setTitle(L10n.clipEditViewMultiselectSelect, for: .normal)
            selectButton.setTitleColor(Asset.Color.likePicsRedClient.color, for: .normal)
            let selectButtonConfiguration = UICellAccessory.CustomViewConfiguration(customView: selectButton,
                                                                                    placement: .trailing(displayed: .whenNotEditing))
            selectButton.addAction(.init(handler: { [weak proxy] _ in
                proxy?.delegate?.didTapSelectionButton()
            }), for: .touchUpInside)

            let cancelButton = UIButton()
            cancelButton.setTitle(L10n.clipEditViewMultiselectCancel, for: .normal)
            cancelButton.setTitleColor(Asset.Color.likePicsRedClient.color, for: .normal)
            let cancelButtonConfiguration = UICellAccessory.CustomViewConfiguration(customView: cancelButton,
                                                                                    placement: .trailing(displayed: .whenEditing))
            cancelButton.addAction(.init(handler: { [weak proxy] _ in
                proxy?.delegate?.didTapCancelSelectionButton()
            }), for: .touchUpInside)

            let editSiteUrlsButton = UIButton()
            editSiteUrlsButton.setTitle(L10n.clipEditViewMultiselectEditUrl, for: .normal)
            editSiteUrlsButton.setTitleColor(Asset.Color.likePicsRedClient.color, for: .normal)
            let editSiteUrlsButtonConfiguration = UICellAccessory.CustomViewConfiguration(customView: editSiteUrlsButton,
                                                                                          placement: .leading(displayed: .whenEditing))
            editSiteUrlsButton.addAction(.init(handler: { [weak proxy] _ in
                proxy?.delegate?.didTapEditSiteUrlsForSelectionButton()
            }), for: .touchUpInside)

            headerView.accessories = [
                .customView(configuration: selectButtonConfiguration),
                .customView(configuration: cancelButtonConfiguration),
                .customView(configuration: editSiteUrlsButtonConfiguration)
            ]
        }
    }
}

// MARK: - Proxy DataSource Delegate

extension ClipEditViewLayout.Proxy {
    func trailingSwipeAction(indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return self.delegate?.trailingSwipeAction(indexPath: indexPath)
    }

    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool) {
        self.delegate?.didSwitchHiding(cell, at: indexPath, isOn: isOn)
    }
}

extension ClipEditViewLayout.Proxy: ButtonCellDelegate {
    // MARK: - ButtonCellDelegate

    func didTap(_ cell: ButtonCell) {
        self.delegate?.didTapTagAdditionButton(cell)
    }
}

extension ClipEditViewLayout.Proxy: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        self.delegate?.didTapTagDeletionButton(cell)
    }
}

extension ClipEditViewLayout.Proxy: ClipItemEditContentDelegate {
    // MARK: - ClipItemEditContentDelegate

    func didTapSiteUrl(_ url: URL?, sender: UIView) {
        self.delegate?.didTapSiteUrl(sender, url: url)
    }

    func didTapSiteUrlEditButton(_ url: URL?, sender: UIView) {
        self.delegate?.didTapSiteUrlEditButton(sender, url: url)
    }
}
