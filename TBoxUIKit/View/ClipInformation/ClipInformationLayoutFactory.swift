//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public enum ClipInformationLayoutFactory {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

    // MARK: Composition

    enum ElementKind: String {
        case layoutHeader
        case sectionHeader
        case sectionBackground
    }

    enum HeaderType {
        case layout
        case section

        var identifier: String {
            switch self {
            case .layout:
                return "header-layout"

            case .section:
                return "header-section"
            }
        }
    }

    enum Section: Int {
        case tag
        case info
    }

    enum ItemType {
        case tag
        case row
        case empty

        var identifier: String {
            switch self {
            case .tag:
                return "item-tag"

            case .row:
                return "item-row"

            case .empty:
                return "item-empty"
            }
        }

        var `class`: UICollectionViewCell.Type {
            switch self {
            case .tag:
                return TagCollectionViewCell.self

            case .row:
                return ClipInformationCell.self

            case .empty:
                return TagCollectionEmptyCell.self
            }
        }
    }

    enum Item: Hashable, Equatable {
        struct Cell: Equatable, Hashable {
            enum Accessory: Equatable, Hashable {
                case label(title: String)
                case button(title: String)
                case `switch`(isOn: Bool)
            }

            let id: String
            let title: String
            let rightAccessory: Accessory?
            let bottomAccessory: Accessory?
            let visibleSeparator: Bool
        }

        case tag(Tag)
        case row(Cell)
        case empty

        var type: ItemType {
            switch self {
            case .tag:
                return .tag

            case .row:
                return .row

            case .empty:
                return .empty
            }
        }
    }

    // MARK: DataSource

    public struct Information {
        public let clip: Clip
        public let item: ClipItem

        public init(clip: Clip, item: ClipItem) {
            self.clip = clip
            self.item = item
        }
    }

    // MARK: - Methods

    // MARK: Preparation

    static func registerCells(to collectionView: UICollectionView) {
        collectionView.register(ClipInformationLayoutHeader.self,
                                forSupplementaryViewOfKind: ElementKind.layoutHeader.rawValue,
                                withReuseIdentifier: HeaderType.layout.identifier)
        collectionView.register(ClipInformationSectionHeader.nib,
                                forSupplementaryViewOfKind: ElementKind.sectionHeader.rawValue,
                                withReuseIdentifier: HeaderType.section.identifier)
        collectionView.register(TagCollectionViewCell.nib,
                                forCellWithReuseIdentifier: ItemType.tag.identifier)
        collectionView.register(ClipInformationCell.nib,
                                forCellWithReuseIdentifier: ItemType.row.identifier)
        collectionView.register(TagCollectionEmptyCell.nib,
                                forCellWithReuseIdentifier: ItemType.empty.identifier)
    }

    // MARK: Layout

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .info:
                return self.createRowsLayoutSection()

            case .none:
                return nil
            }
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 16

        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .absolute(20))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize,
                                                                 elementKind: ElementKind.layoutHeader.rawValue,
                                                                 alignment: .top)
        config.boundarySupplementaryItems = [header]

        layout.configuration = config

        layout.register(ClipInformationSectionBackgroundDecorationView.self,
                        forDecorationViewOfKind: ElementKind.sectionBackground.rawValue)

        return layout
    }

    private static func createTagsLayoutSection() -> NSCollectionLayoutSection {
        let groupEdgeSpacing = NSCollectionLayoutEdgeSpacing(leading: nil,
                                                             top: nil,
                                                             trailing: nil,
                                                             bottom: .fixed(4))
        let groupContentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)
        let section = TagCollectionView.createLayoutSection(groupEdgeSpacing: groupEdgeSpacing,
                                                            groupContentInsets: groupContentInsets)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                        elementKind: ElementKind.sectionHeader.rawValue,
                                                                        alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]

        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 4, trailing: 0)

        let sectionBackgroundDecoration = NSCollectionLayoutDecorationItem.background(
            elementKind: ElementKind.sectionBackground.rawValue
        )

        section.decorationItems = [sectionBackgroundDecoration]

        return section
    }

    private static func createRowsLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                              heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                        elementKind: ElementKind.sectionHeader.rawValue,
                                                                        alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]

        let sectionBackgroundDecoration = NSCollectionLayoutDecorationItem.background(
            elementKind: ElementKind.sectionBackground.rawValue
        )

        section.decorationItems = [sectionBackgroundDecoration]

        return section
    }

    // MARK: DataSource

    static func makeDataSource(for collectionView: UICollectionView,
                               infoCellDelegate: ClipInformationCellDelegate?,
                               tagCellDelegate: TagCollectionViewCellDelegate?,
                               sectionHeaderDelegate: ClipInformationSectionHeaderDelegate?) -> DataSource
    {
        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak tagCellDelegate] collectionView, indexPath, item -> UICollectionViewCell? in
            switch Section(rawValue: indexPath.section) {
            case .tag:
                return self.tagsSectionCellProvider(delegate: tagCellDelegate)(collectionView, indexPath, item)

            case .info:
                return self.infoSectionCellProvider(delegate: infoCellDelegate)(collectionView, indexPath, item)

            case .none:
                return nil
            }
        }

        dataSource.supplementaryViewProvider = self.headerProvider(delegate: sectionHeaderDelegate)

        return dataSource
    }

    private static func tagsSectionCellProvider(delegate: TagCollectionViewCellDelegate?) -> DataSource.CellProvider {
        return { [weak delegate] collectionView, indexPath, item -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: item.type.identifier,
                                                                  for: indexPath)

            switch item.type {
            case .empty:
                guard let cell = dequeuedCell as? TagCollectionEmptyCell else { return dequeuedCell }
                guard case .empty = item else { return cell }
                cell.message = L10n.clipInformationViewLabelEmpty
                return cell

            case .tag:
                guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }
                guard case let .tag(tag) = item else { return cell }
                cell.title = tag.name
                cell.displayMode = .normal
                cell.visibleDeleteButton = true
                cell.delegate = delegate

                return cell

            default:
                return nil
            }
        }
    }

    private static func infoSectionCellProvider(delegate: ClipInformationCellDelegate?) -> DataSource.CellProvider {
        return { [weak delegate] collectionView, indexPath, item -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: item.type.identifier,
                                                                  for: indexPath)
            guard let cell = dequeuedCell as? ClipInformationCell else { return dequeuedCell }
            guard case let .row(info) = item else { return cell }

            cell.title = info.title
            cell.delegate = delegate

            switch info.rightAccessory {
            case let .label(title: title):
                cell.rightAccessoryType = .label(title: title)

            case let .switch(isOn: isOn):
                cell.rightAccessoryType = .switch(isOn: isOn)

            default:
                cell.rightAccessoryType = nil
            }

            switch info.bottomAccessory {
            case let .button(title: title):
                cell.bottomAccessoryType = .button(title: title)

            default:
                cell.bottomAccessoryType = nil
            }

            cell.visibleSeparator = info.visibleSeparator

            return cell
        }
    }

    private static func headerProvider(delegate: ClipInformationSectionHeaderDelegate?) -> UICollectionViewDiffableDataSource<Section, Item>.SupplementaryViewProvider {
        return { [weak delegate] collectionView, kind, indexPath -> UICollectionReusableView? in
            let identifier: String
            switch ElementKind(rawValue: kind) {
            case .layoutHeader:
                identifier = HeaderType.layout.identifier

            case .sectionHeader:
                identifier = HeaderType.section.identifier

            case .sectionBackground, .none:
                return nil
            }

            let dequeuedHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)

            guard ElementKind(rawValue: kind) != .layoutHeader else {
                return dequeuedHeader
            }

            guard let header = dequeuedHeader as? ClipInformationSectionHeader else {
                return nil
            }

            header.delegate = delegate

            switch Section(rawValue: indexPath.section) {
            case .tag:
                header.identifier = "\(Section.tag.rawValue)"
                header.title = L10n.clipInformationViewSectionLabelTag
                header.visibleAddButton = true

            case .info:
                header.identifier = "\(Section.info.rawValue)"
                header.title = L10n.clipInformationViewSectionLabelClipItem
                header.visibleAddButton = false

            case .none:
                return nil
            }

            return header
        }
    }

    private static func format(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }

    // MARK: Snapshot

    static func makeSnapshot(for info: Information) -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tag])
        if info.clip.tags.isEmpty {
            snapshot.appendItems([.empty])
        } else {
            snapshot.appendItems(info.clip.tags.map { .tag($0) })
        }
        snapshot.appendSections([.info])
        snapshot.appendItems(self.createCells(for: info.item, clip: info.clip))
        return snapshot
    }

    // MARK: Privates

    private static func createCells(for clipItem: ClipItem, clip: Clip) -> [Item] {
        var items: [Item.Cell] = []

        if let imageUrl = clipItem.imageUrl {
            items.append(Item.Cell(id: UUID().uuidString,
                                   title: L10n.clipInformationViewLabelClipItemUrl,
                                   rightAccessory: nil,
                                   bottomAccessory: .button(title: imageUrl.absoluteString),
                                   visibleSeparator: false))
        } else {
            items.append(Item.Cell(id: UUID().uuidString,
                                   title: L10n.clipInformationViewLabelClipItemUrl,
                                   rightAccessory: .label(title: L10n.clipInformationViewLabelClipItemNoUrl),
                                   bottomAccessory: nil,
                                   visibleSeparator: false))
        }

        if let siteUrl = clipItem.url {
            items.append(Item.Cell(id: UUID().uuidString,
                                   title: L10n.clipInformationViewLabelClipUrl,
                                   rightAccessory: nil,
                                   bottomAccessory: .button(title: siteUrl.absoluteString),
                                   visibleSeparator: true))
        } else {
            items.append(Item.Cell(id: UUID().uuidString,
                                   title: L10n.clipInformationViewLabelClipItemUrl,
                                   rightAccessory: .button(title: L10n.clipInformationViewLabelClipItemNoUrl),
                                   bottomAccessory: nil,
                                   visibleSeparator: true))
        }

        return (items + [
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipItemSize,
                      rightAccessory: .label(title: ByteCountFormatter.string(fromByteCount: Int64(clipItem.imageDataSize),
                                                                              countStyle: .binary)),
                      bottomAccessory: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipHide,
                      rightAccessory: .switch(isOn: clip.isHidden),
                      bottomAccessory: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipItemRegisteredDate,
                      rightAccessory: .label(title: self.format(clipItem.registeredDate)),
                      bottomAccessory: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipItemUpdatedDate,
                      rightAccessory: .label(title: self.format(clipItem.updatedDate)),
                      bottomAccessory: nil,
                      visibleSeparator: true)
        ]).map { .row($0) }
    }
}
