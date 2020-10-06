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
        case clipItemInformation
        case clipTag
        case clipInformation
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
            let id: String
            let title: String
            let rightLabel: String?
            let bottomLabel: String?
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
            case .clipTag:
                return self.createTagsLayoutSection()

            case .clipInformation, .clipItemInformation:
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
                               configureUrlLink: @escaping (UIButton) -> Void,
                               delegate: ClipInformationSectionHeaderDelegate?) -> DataSource
    {
        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch Section(rawValue: indexPath.section) {
            case .clipTag:
                return self.tagsSectionCellProvider()(collectionView, indexPath, item)

            case .clipInformation, .clipItemInformation:
                return self.infoSectionCellProvider(configureUrlLink: configureUrlLink)(collectionView, indexPath, item)

            case .none:
                return nil
            }
        }

        dataSource.supplementaryViewProvider = self.headerProvider(delegate: delegate)

        return dataSource
    }

    private static func tagsSectionCellProvider() -> DataSource.CellProvider {
        return { collectionView, indexPath, item -> UICollectionViewCell? in
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
                return cell

            default:
                return nil
            }
        }
    }

    private static func infoSectionCellProvider(configureUrlLink: @escaping (UIButton) -> Void) -> DataSource.CellProvider {
        return { collectionView, indexPath, item -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: item.type.identifier,
                                                                  for: indexPath)
            guard let cell = dequeuedCell as? ClipInformationCell else { return dequeuedCell }
            guard case let .row(info) = item else { return cell }

            cell.titleLabel.text = info.title

            if let rightTitle = info.rightLabel {
                cell.visibleRightAccessoryView = true
                cell.rightAccessoryLabel.text = rightTitle
            } else {
                cell.visibleRightAccessoryView = false
            }

            if let bottomTitle = info.bottomLabel {
                cell.visibleBottomAccessoryView = true
                cell.bottomAccessoryButton.setTitle(bottomTitle, for: .normal)
                configureUrlLink(cell.bottomAccessoryButton)
            } else {
                cell.visibleBottomAccessoryView = false
            }

            cell.visibleSeparator = info.visibleSeparator

            return cell
        }
    }

    private static func headerProvider(delegate: ClipInformationSectionHeaderDelegate?) -> UICollectionViewDiffableDataSource<Section, Item>.SupplementaryViewProvider {
        return { collectionView, kind, indexPath -> UICollectionReusableView? in
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
            case .clipTag:
                header.identifier = "\(Section.clipTag.rawValue)"
                header.title = L10n.clipInformationViewSectionLabelTag
                header.visibleAddButton = true

            case .clipInformation:
                header.identifier = "\(Section.clipInformation.rawValue)"
                header.title = L10n.clipInformationViewSectionLabelClip
                header.visibleAddButton = false

            case .clipItemInformation:
                header.identifier = "\(Section.clipItemInformation.rawValue)"
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
        snapshot.appendSections([.clipItemInformation])
        snapshot.appendItems(self.createCells(for: info.item))
        snapshot.appendSections([.clipTag])
        if info.clip.tags.isEmpty {
            snapshot.appendItems([.empty])
        } else {
            snapshot.appendItems(info.clip.tags.map { .tag($0) })
        }
        snapshot.appendSections([.clipInformation])
        snapshot.appendItems(self.createCells(for: info.clip))
        return snapshot
    }

    // MARK: Privates

    private static func createCells(for clip: Clip) -> [Item] {
        return [
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipUrl,
                      rightLabel: nil,
                      bottomLabel: clip.url.absoluteString,
                      visibleSeparator: false),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipHide,
                      rightLabel: clip.isHidden
                          ? L10n.clipInformationViewAccessoryClipHideYes
                          : L10n.clipInformationViewAccessoryClipHideNo,
                      bottomLabel: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipRegisteredDate,
                      rightLabel: self.format(clip.registeredDate),
                      bottomLabel: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipUpdatedDate,
                      rightLabel: self.format(clip.updatedDate),
                      bottomLabel: nil,
                      visibleSeparator: true)
        ].map { .row($0) }
    }

    private static func createCells(for clipItem: ClipItem) -> [Item] {
        return [
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipItemUrl,
                      rightLabel: nil,
                      bottomLabel: clipItem.imageUrl.absoluteString,
                      visibleSeparator: false),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipItemRegisteredDate,
                      rightLabel: self.format(clipItem.registeredDate),
                      bottomLabel: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: L10n.clipInformationViewLabelClipItemUpdatedDate,
                      rightLabel: self.format(clipItem.updatedDate),
                      bottomLabel: nil,
                      visibleSeparator: true)
        ].map { .row($0) }
    }
}
