//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

protocol ClipItemInformationLayoutDelegate: AnyObject {
    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool)
    func didTapTagDeletionButton(_ cell: UICollectionViewCell)
    func didTapSiteUrl(_ cell: UICollectionViewCell, url: URL)
    func didTapSiteUrlEditButton(_ cell: UICollectionViewCell, url: URL?)
}

public enum ClipItemInformationLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

    enum Section: Int {
        case itemInfo
        case tags
        case albums
        case clipInfo
    }

    enum Item: Hashable, Equatable {
        case tag(Tag)
        case album(ListingAlbum)
        case meta(Info)
        case url(UrlSetting)
    }

    enum ElementKind: String {
        case header
    }

    struct Info: Equatable, Hashable {
        enum Parent {
            case item
            case clip
        }

        enum Accessory: Equatable, Hashable {
            case label(title: String)
            case `switch`(isOn: Bool)
        }

        let parent: Parent
        let title: String
        let accessory: Accessory
    }

    struct UrlSetting: Equatable, Hashable {
        let title: String
        let url: URL?
        let isEditable: Bool
    }

    // MARK: DataSource

    public struct Information: Equatable {
        public let clip: Clip?
        public let tags: [Tag]
        public let albums: [ListingAlbum]
        public let item: ClipItem?

        public init(clip: Clip?, tags: [Tag], albums: [ListingAlbum], item: ClipItem?) {
            self.clip = clip
            self.tags = tags
            self.albums = albums
            self.item = item
        }
    }
}

// MARK: - Layout

extension ClipItemInformationLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tags:
                return createTagsLayoutSection()

            default:
                return createPlainLayoutSection(environment: environment)
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
        group.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(12)
        section.contentInsets = .init(top: 16, leading: 0, bottom: 0, trailing: 0)

        let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(44))
        section.boundarySupplementaryItems = [
            .init(layoutSize: titleSize, elementKind: ElementKind.header.rawValue, alignment: .top)
        ]

        return section
    }

    private static func createPlainLayoutSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        configuration.backgroundColor = .clear
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

        let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(44))
        section.boundarySupplementaryItems = [
            .init(layoutSize: titleSize, elementKind: ElementKind.header.rawValue, alignment: .top)
        ]

        return section
    }
}

// MARK: - Snapshot

extension ClipItemInformationLayout {
    static func makeSnapshot(for info: Information?) -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        snapshot.appendSections([.itemInfo])
        snapshot.appendItems(self.createCells(for: info?.item))

        snapshot.appendSections([.tags])
        snapshot.appendItems(info?.tags.map({ .tag($0) }) ?? [])

        snapshot.appendSections([.albums])
        snapshot.appendItems(info?.albums.map({ .album($0) }) ?? [])

        snapshot.appendSections([.clipInfo])
        snapshot.appendItems(self.createCells(for: info?.clip))

        return snapshot
    }

    private static func createCells(for clipItem: ClipItem?) -> [Item] {
        var items: [Item] = []

        items.append(.url(.init(title: L10n.clipInformationViewLabelClipItemImageUrl,
                                url: clipItem?.imageUrl,
                                isEditable: false)))
        items.append(.url(.init(title: L10n.clipInformationViewLabelClipItemUrl,
                                url: clipItem?.url,
                                isEditable: true)))

        let size: String = {
            guard let dataSize = clipItem?.imageDataSize else { return "-" }
            return ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .binary)
        }()
        items.append(.meta(.init(parent: .item,
                                 title: L10n.clipInformationViewLabelClipItemSize,
                                 accessory: .label(title: size))))

        let registeredDate: String = {
            guard let date = clipItem?.registeredDate else { return "-" }
            return self.format(date)
        }()
        items.append(.meta(.init(parent: .item,
                                 title: L10n.clipInformationViewLabelClipItemRegisteredDate,
                                 accessory: .label(title: registeredDate))))
        let updatedDate: String = {
            guard let date = clipItem?.updatedDate else { return "-" }
            return self.format(date)
        }()
        items.append(.meta(.init(parent: .item,
                                 title: L10n.clipInformationViewLabelClipItemUpdatedDate,
                                 accessory: .label(title: updatedDate))))

        return items
    }

    private static func createCells(for clip: Clip?) -> [Item] {
        var items: [Item] = []

        items.append(.meta(.init(parent: .clip,
                                 title: L10n.clipInformationViewLabelClipHide,
                                 accessory: .switch(isOn: clip?.isHidden ?? false))))

        let size: String = {
            guard let dataSize = clip?.dataSize else { return "-" }
            return ByteCountFormatter.string(fromByteCount: Int64(dataSize), countStyle: .binary)
        }()
        items.append(.meta(.init(parent: .clip,
                                 title: L10n.clipInformationViewLabelClipSize,
                                 accessory: .label(title: size))))

        let registeredDate: String = {
            guard let date = clip?.registeredDate else { return "-" }
            return self.format(date)
        }()
        items.append(.meta(.init(parent: .clip,
                                 title: L10n.clipInformationViewLabelClipRegisteredDate,
                                 accessory: .label(title: registeredDate))))
        let updatedDate: String = {
            guard let date = clip?.updatedDate else { return "-" }
            return self.format(date)
        }()
        items.append(.meta(.init(parent: .clip,
                                 title: L10n.clipInformationViewLabelClipUpdatedDate,
                                 accessory: .label(title: updatedDate))))

        return items
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - DataSource

extension ClipItemInformationLayout {
    class Proxy: NSObject {
        weak var delegate: ClipItemInformationLayoutDelegate?
        weak var interactionDelegate: UIContextMenuInteractionDelegate?
    }

    static var font = UIFont.preferredFont(forTextStyle: .callout)

    static func makeDataSource(for collectionView: UICollectionView,
                               tagAdditionHandler: @escaping () -> Void,
                               albumAdditionHandler: @escaping () -> Void) -> (DataSource, Proxy)
    {
        let proxy = Proxy()

        let tagCellRegistration = self.configureTagCell(delegate: proxy)
        let albumCellRegistration = self.configureAlbumCell()
        let metaCellRegistration = self.configureMetaCell(proxy: proxy)
        let urlCellRegistration = self.configureUrlCell(proxy: proxy)

        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .album(album):
                return collectionView.dequeueConfiguredReusableCell(using: albumCellRegistration, for: indexPath, item: album)

            case let .meta(meta):
                return collectionView.dequeueConfiguredReusableCell(using: metaCellRegistration, for: indexPath, item: meta)

            case let .url(setting):
                return collectionView.dequeueConfiguredReusableCell(using: urlCellRegistration, for: indexPath, item: setting)
            }
        }

        let headerRegistration = configureHeader(tagAdditionHandler: tagAdditionHandler,
                                                 albumAdditionHandler: albumAdditionHandler)
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            switch ElementKind(rawValue: elementKind) {
            case .header:
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)

            default:
                return nil
            }
        }

        return (dataSource, proxy)
    }

    private static func configureHeader(tagAdditionHandler: @escaping () -> Void,
                                        albumAdditionHandler: @escaping () -> Void) -> UICollectionView.SupplementaryRegistration<ListSectionHeaderView>
    {
        return .init(elementKind: ElementKind.header.rawValue) { view, _, indexPath in
            let title: String = {
                switch Section(rawValue: indexPath.section) {
                case .itemInfo:
                    return L10n.clipInformationViewSectionLabelClipItemInfo

                case .clipInfo:
                    return L10n.clipInformationViewSectionLabelClipInfo

                case .tags:
                    return L10n.clipInformationViewSectionLabelTags

                case .albums:
                    return L10n.clipInformationViewSectionLabelAlbums

                case .none:
                    return ""
                }
            }()
            view.title = title
            view.setTitleTextStyle(.headline)

            switch Section(rawValue: indexPath.section) {
            case .tags:
                view.setRightItems([
                    .init(title: L10n.clipInformationViewLabelTagAddition,
                          action: UIAction(handler: { _ in tagAdditionHandler() }),
                          font: Self.font,
                          insets: .zero)
                ])

            case .albums:
                view.setRightItems([
                    .init(title: L10n.clipInformationViewLabelAlbumAddition,
                          action: UIAction(handler: { _ in albumAdditionHandler() }),
                          font: Self.font,
                          insets: .zero)
                ])

            default:
                view.setRightItems([])
            }
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

    private static func configureAlbumCell() -> UICollectionView.CellRegistration<UICollectionViewListCell, ListingAlbum> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, ListingAlbum> { cell, _, album in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = album.title
            contentConfiguration.textProperties.color = Asset.Color.likePicsRed.color
            contentConfiguration.textProperties.font = Self.font
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureMetaCell(proxy: Proxy) -> UICollectionView.CellRegistration<UICollectionViewListCell, Info> {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Info> { cell, indexPath, info in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = info.title
            contentConfiguration.textProperties.font = Self.font
            cell.contentConfiguration = contentConfiguration

            switch info.accessory {
            case let .label(title: title):
                cell.accessories = [.label(text: title, displayed: .always, options: .init(font: Self.font))]

            case let .switch(isOn: isOn):
                // swiftlint:disable:next identifier_name
                let sw = UISwitch()
                sw.isOn = isOn
                sw.addAction(.init(handler: { [weak proxy] action in
                    // swiftlint:disable:next identifier_name
                    guard let sw = action.sender as? UISwitch else { return }
                    proxy?.delegate?.didSwitchHiding(cell, at: indexPath, isOn: sw.isOn)
                }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: sw, placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]
            }

            var backgroundConfiguration = UIBackgroundConfiguration.listPlainCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureUrlCell(proxy: Proxy) -> UICollectionView.CellRegistration<ListCell, UrlSetting> {
        return UICollectionView.CellRegistration<ListCell, UrlSetting>(cellNib: ListCell.nib) { cell, _, setting in
            cell.backgroundColor = Asset.Color.secondaryBackground.color

            cell.setFont(Self.font)
            cell.title = setting.title
            cell.rightAccessoryType = setting.isEditable ? .button(title: L10n.clipInformationViewLabelClipItemEditUrl) : nil

            if let url = setting.url {
                cell.bottomAccessoryType = .button(title: url.absoluteString)
            } else {
                cell.bottomAccessoryType = .label(title: L10n.clipInformationViewLabelClipItemNoUrl)
            }

            cell.delegate = proxy
            cell.interactionDelegate = proxy.interactionDelegate
        }
    }
}

// MARK: - Proxy DataSource Delegate

extension ClipItemInformationLayout.Proxy: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        self.delegate?.didTapTagDeletionButton(cell)
    }
}

extension ClipItemInformationLayout.Proxy: ListCellDelegate {
    // MARK: - ListCellDelegate

    func listCell(_ cell: ListCell, didSwitchRightAccessory switch: UISwitch) {
        // NOP
    }

    func listCell(_ cell: ListCell, didTapRightAccessory button: UIButton) {
        let url: URL? = {
            if case let .button(title: title) = cell.bottomAccessoryType, let url = URL(string: title) {
                return url
            } else {
                return nil
            }
        }()
        self.delegate?.didTapSiteUrlEditButton(cell, url: url)
    }

    func listCell(_ cell: ListCell, didTapBottomAccessory button: UIButton) {
        guard case let .button(title: title) = cell.bottomAccessoryType, let url = URL(string: title) else { return }
        self.delegate?.didTapSiteUrl(cell, url: url)
    }
}
