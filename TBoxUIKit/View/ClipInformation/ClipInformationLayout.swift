//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

protocol ClipInformationLayoutDelegate: AnyObject {
    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool)
    func didTapTagAdditionButton(_ cell: UICollectionViewCell)
    func didTapTagDeletionButton(_ cell: UICollectionViewCell)
    func didTapSiteUrl(_ cell: UICollectionViewCell, url: URL)
    func didTapSiteUrlEditButton(_ cell: UICollectionViewCell, url: URL?)
}

public enum ClipInformationLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

    enum Section: Int {
        case tag
        case info
    }

    enum Item: Hashable, Equatable {
        case tagAddition
        case tag(Tag)
        case meta(Info)
        case url(UrlSetting)
    }

    struct Info: Equatable, Hashable {
        enum Accessory: Equatable, Hashable {
            case label(title: String)
            case `switch`(isOn: Bool)
        }

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
        public let item: ClipItem?

        public init(clip: Clip?, tags: [Tag], item: ClipItem?) {
            self.clip = clip
            self.tags = tags
            self.item = item
        }
    }
}

// MARK: - Layout

extension ClipInformationLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .info:
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.background.color
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
}

// MARK: - Snapshot

extension ClipInformationLayout {
    static func makeSnapshot(for info: Information) -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tag])
        snapshot.appendItems([.tagAddition] + info.tags.map { .tag($0) })
        snapshot.appendSections([.info])
        snapshot.appendItems(self.createCells(for: info.item, clip: info.clip))
        return snapshot
    }

    private static func createCells(for clipItem: ClipItem?, clip: Clip?) -> [Item] {
        var items: [Item] = []

        if let clipItem = clipItem {
            items.append(.url(.init(title: L10n.clipInformationViewLabelClipItemUrl,
                                    url: clipItem.imageUrl,
                                    isEditable: false)))
            items.append(.url(.init(title: L10n.clipInformationViewLabelClipUrl,
                                    url: clipItem.url,
                                    isEditable: true)))

            items.append(.meta(.init(title: L10n.clipInformationViewLabelClipItemSize,
                                     accessory: .label(title: ByteCountFormatter.string(fromByteCount: Int64(clipItem.imageDataSize),
                                                                                        countStyle: .binary)))))
        }

        if let clip = clip {
            items.append(.meta(.init(title: L10n.clipInformationViewLabelClipHide,
                                     accessory: .switch(isOn: clip.isHidden))))
        }

        if let clipItem = clipItem {
            items.append(.meta(.init(title: L10n.clipInformationViewLabelClipItemRegisteredDate,
                                     accessory: .label(title: self.format(clipItem.registeredDate)))))
            items.append(.meta(.init(title: L10n.clipInformationViewLabelClipItemUpdatedDate,
                                     accessory: .label(title: self.format(clipItem.updatedDate)))))
        }

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

extension ClipInformationLayout {
    class Proxy: NSObject {
        weak var delegate: ClipInformationLayoutDelegate?
        weak var interactionDelegate: UIContextMenuInteractionDelegate?
    }

    static func makeDataSource(for collectionView: UICollectionView) -> (DataSource, Proxy) {
        let proxy = Proxy()

        let tagAdditionCellRegistration = self.configureTagAdditionCell(delegate: proxy)
        let tagCellRegistration = self.configureTagCell(delegate: proxy)
        let metaCellRegistration = self.configureMetaCell(proxy: proxy)
        let urlCellRegistration = self.configureUrlCell(proxy: proxy)

        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .meta(meta):
                return collectionView.dequeueConfiguredReusableCell(using: metaCellRegistration, for: indexPath, item: meta)

            case let .url(setting):
                return collectionView.dequeueConfiguredReusableCell(using: urlCellRegistration, for: indexPath, item: setting)
            }
        }
        return (dataSource, proxy)
    }

    private static func configureTagAdditionCell(delegate: ButtonCellDelegate) -> UICollectionView.CellRegistration<ButtonCell, Void> {
        return UICollectionView.CellRegistration<ButtonCell, Void>(cellNib: ButtonCell.nib) { [weak delegate] cell, _, _ in
            cell.title = L10n.clipInformationViewLabelTagAddition
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
                    proxy?.delegate?.didSwitchHiding(cell, at: indexPath, isOn: sw.isOn)
                }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: sw, placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]
            }

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    private static func configureUrlCell(proxy: Proxy) -> UICollectionView.CellRegistration<ListCell, UrlSetting> {
        return UICollectionView.CellRegistration<ListCell, UrlSetting>(cellNib: ListCell.nib) { cell, _, setting in
            cell.backgroundColor = Asset.Color.secondaryBackground.color

            cell.title = setting.title
            cell.rightAccessoryType = setting.isEditable ? .button(title: L10n.clipInformationViewLabelClipEditUrl) : nil

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

extension ClipInformationLayout.Proxy: ButtonCellDelegate {
    // MARK: - ButtonCellDelegate

    func didTap(_ cell: ButtonCell) {
        self.delegate?.didTapTagAdditionButton(cell)
    }
}

extension ClipInformationLayout.Proxy: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        self.delegate?.didTapTagDeletionButton(cell)
    }
}

extension ClipInformationLayout.Proxy: ListCellDelegate {
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
