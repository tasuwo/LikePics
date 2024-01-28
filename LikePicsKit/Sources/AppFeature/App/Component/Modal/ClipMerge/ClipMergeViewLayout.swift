//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import Smoothie
import UIKit

protocol ClipMergeViewDelegate: AnyObject {
    func didTapButton(_ cell: UICollectionViewCell, at indexPath: IndexPath)
    func didSwitch(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool)
    func didTapTagAdditionButton(_ cell: UICollectionViewCell)
    func didTapTagDeletionButton(_ cell: UICollectionViewCell)
    func didTapSiteUrl(_ sender: UIView, url: URL?)
}

enum ClipMergeViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case tag
        case meta
        case clip
    }

    enum Item: Hashable {
        case tagAddition
        case tag(Tag)
        case meta(Info)
        case item(ClipItem)

        var dragIdentifier: String? {
            switch self {
            case let .item(item): item.id.uuidString
            default: nil
            }
        }
    }

    public struct Info: Equatable, Hashable {
        enum Accessory: Equatable, Hashable {
            case button(title: String)
            case `switch`(isOn: Bool)
        }

        let title: String
        let secondaryTitle: String?
        let accessory: Accessory
    }
}

// MARK: - Compositional Layout

extension ClipMergeViewLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .meta:
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.background.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

            case .clip:
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

// MARK: - DataSource

extension ClipMergeViewLayout {
    class Proxy {
        weak var delegate: ClipMergeViewDelegate?
        weak var interactionDelegate: UIContextMenuInteractionDelegate?
    }

    static func createSnapshot(tags: [Tag], items: [ClipItem], state: ClipMergeViewState) -> Snapshot {
        var snapshot = Snapshot()
        snapshot.appendSections([.tag])
        snapshot.appendItems([Item.tagAddition] + tags.map({ Item.tag($0) }))

        snapshot.appendSections([.meta])
        snapshot.appendItems([
            .meta(.init(title: L10n.clipMergeViewMetaUrlTitle,
                        secondaryTitle: state.overwriteSiteUrl?.absoluteString ?? L10n.clipMergeViewMetaUrlNo,
                        accessory: (state.overwriteSiteUrl.flatMap({ $0.absoluteString.isEmpty }) ?? true)
                            ? .button(title: L10n.clipMergeViewMetaUrlOverwrite)
                            : .button(title: L10n.clipMergeViewMetaUrlEdit))),
            .meta(.init(title: L10n.clipMergeViewMetaShouldHides,
                        secondaryTitle: nil,
                        accessory: .switch(isOn: state.shouldSaveAsHiddenItem)))
        ])

        snapshot.appendSections([.clip])
        snapshot.appendItems(items.map({ Item.item($0) }))
        return snapshot
    }

    static func createItems(tags: [Tag], items: [ClipItem]) -> [Item] {
        return [Item.tagAddition]
            + tags.map({ Item.tag($0) })
            + items.map({ Item.item($0) })
    }

    @MainActor
    static func createDataSource(_ collectionView: UICollectionView,
                                 _ thumbnailProcessingQueue: ImageProcessingQueue,
                                 _ imageQueryService: ImageQueryServiceProtocol) -> (DataSource, Proxy)
    {
        let proxy = Proxy()

        let tagAdditionCellRegistration = self.configureTagAdditionCell(delegate: proxy)
        let tagCellRegistration = self.configureTagCell(delegate: proxy)
        let metaCellRegistration = self.configureMetaCell(proxy: proxy)
        let itemCellRegistration = self.configureItemCell(proxy: proxy,
                                                          thumbnailProcessingQueue: thumbnailProcessingQueue,
                                                          imageQueryService: imageQueryService)

        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .meta(info):
                return collectionView.dequeueConfiguredReusableCell(using: metaCellRegistration, for: indexPath, item: info)

            case let .item(item):
                return collectionView.dequeueConfiguredReusableCell(using: itemCellRegistration, for: indexPath, item: item)
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
            contentConfiguration.secondaryText = info.secondaryTitle
            contentConfiguration.secondaryTextProperties.font = .preferredFont(forTextStyle: .caption1)
            cell.contentConfiguration = contentConfiguration

            switch info.accessory {
            case let .button(title: title):
                let button = UIButton(type: .system)
                button.isPointerInteractionEnabled = true
                button.setTitle(title, for: .normal)
                button.addAction(.init(handler: { [weak proxy] _ in
                    proxy?.delegate?.didTapButton(cell, at: indexPath)
                }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: button,
                                                                            placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]

            case let .switch(isOn: isOn):
                // swiftlint:disable:next identifier_name
                let sw = UISwitch()
                sw.isOn = isOn
                sw.addAction(.init(handler: { [weak proxy] action in
                    // swiftlint:disable:next identifier_name
                    guard let sw = action.sender as? UISwitch else { return }
                    proxy?.delegate?.didSwitch(cell, at: indexPath, isOn: sw.isOn)
                }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: sw,
                                                                            placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]
            }

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }

    @MainActor
    private static func configureItemCell(proxy: Proxy,
                                          thumbnailProcessingQueue: ImageProcessingQueue,
                                          imageQueryService: ImageQueryServiceProtocol) -> UICollectionView.CellRegistration<ClipItemEditListCell, ClipItem>
    {
        return UICollectionView.CellRegistration<ClipItemEditListCell, ClipItem> { [weak proxy, weak thumbnailProcessingQueue, weak imageQueryService] cell, _, item in
            var contentConfiguration = ClipItemEditContentConfiguration()
            contentConfiguration.siteUrl = item.url
            contentConfiguration.isSiteUrlEditable = false
            contentConfiguration.dataSize = Int(item.imageDataSize)
            contentConfiguration.imageWidth = item.imageSize.width
            contentConfiguration.imageHeight = item.imageSize.height
            contentConfiguration.delegate = proxy
            contentConfiguration.interactionDelegate = proxy?.interactionDelegate
            cell.contentConfiguration = contentConfiguration

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration

            cell.accessories = [.reorder(displayed: .always)]

            guard let processingQueue = thumbnailProcessingQueue,
                  let imageQueryService = imageQueryService else { return }

            let scale = cell.traitCollection.displayScale
            let size = cell.calcThumbnailPointSize(originalPixelSize: item.imageSize.cgSize)
            let request = ImageRequest(resize: .init(size: size, scale: scale), cacheKey: "clip-merge-\(item.identity.uuidString)") {
                try? imageQueryService.read(having: item.imageId)
            }
            loadImage(request, with: processingQueue, on: cell)
        }
    }
}

// MARK: - Proxy DataSource Delegate

extension ClipMergeViewLayout.Proxy: ButtonCellDelegate {
    // MARK: - ButtonCellDelegate

    func didTap(_ cell: ButtonCell) {
        self.delegate?.didTapTagAdditionButton(cell)
    }
}

extension ClipMergeViewLayout.Proxy: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        self.delegate?.didTapTagDeletionButton(cell)
    }
}

extension ClipMergeViewLayout.Proxy: ClipItemEditContentDelegate {
    // MARK: - ClipItemEditContentDelegate

    func didTapSiteUrl(_ url: URL?, sender: UIView) {
        self.delegate?.didTapSiteUrl(sender, url: url)
    }

    func didTapSiteUrlEditButton(_ url: URL?, sender: UIView) {
        // NOP
    }
}
