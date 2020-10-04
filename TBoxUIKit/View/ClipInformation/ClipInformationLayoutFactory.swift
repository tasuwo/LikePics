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

        var identifier: String {
            switch self {
            case .tag:
                return "item-tag"

            case .row:
                return "item-row"
            }
        }

        var `class`: UICollectionViewCell.Type {
            switch self {
            case .tag:
                return TagCollectionViewCell.self

            case .row:
                return ClipInformationCell.self
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

        var type: ItemType {
            switch self {
            case .tag:
                return .tag

            case .row:
                return .row
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
    }

    // MARK: Layout

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .clipTag:
                return self.createTagCreateLayoutSection()

            case .clipInformation, .clipItemInformation:
                return self.createListCreateLayoutSection()

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

    private static func createTagCreateLayoutSection() -> NSCollectionLayoutSection {
        let section = TagCollectionView.createLayoutSection()

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .estimated(44))
        let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                                        elementKind: ElementKind.sectionHeader.rawValue,
                                                                        alignment: .top)
        section.boundarySupplementaryItems = [sectionHeader]

        section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 10, trailing: 0)

        let sectionBackgroundDecoration = NSCollectionLayoutDecorationItem.background(
            elementKind: ElementKind.sectionBackground.rawValue
        )

        section.decorationItems = [sectionBackgroundDecoration]

        return section
    }

    private static func createListCreateLayoutSection() -> NSCollectionLayoutSection {
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
                               configureUrlLink: @escaping (UIButton) -> Void) -> DataSource
    {
        let tagCellProvider: DataSource.CellProvider = { collectionView, indexPath, item -> UICollectionViewCell? in
            let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: item.type.identifier,
                                                                  for: indexPath)

            guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }
            guard case let .tag(tag) = item else { return cell }

            cell.title = tag.name

            return cell
        }

        let infoCellProvider: DataSource.CellProvider = { collectionView, indexPath, item -> UICollectionViewCell? in
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

        let dataSource: DataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch Section(rawValue: indexPath.section) {
            case .clipTag:
                return tagCellProvider(collectionView, indexPath, item)

            case .clipInformation, .clipItemInformation:
                return infoCellProvider(collectionView, indexPath, item)

            case .none:
                return nil
            }
        }

        let headerProvider: UICollectionViewDiffableDataSource<Section, Item>.SupplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
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

            switch Section(rawValue: indexPath.section) {
            case .clipTag:
                header.title = "このクリップのタグ"

            case .clipInformation:
                header.title = "このクリップの情報"

            case .clipItemInformation:
                header.title = "この画像の情報"

            case .none:
                return nil
            }

            return header
        }

        dataSource.supplementaryViewProvider = headerProvider

        return dataSource
    }

    // MARK: Snapshot

    static func makeSnapshot(for info: Information) -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.clipItemInformation])
        snapshot.appendItems(self.createCells(for: info.item))
        snapshot.appendSections([.clipTag])
        snapshot.appendItems(info.clip.tags.map { .tag($0) })
        snapshot.appendSections([.clipInformation])
        snapshot.appendItems(self.createCells(for: info.clip))
        return snapshot
    }

    // MARK: Privates

    private static func createCells(for clip: Clip) -> [Item] {
        return [
            Item.Cell(id: UUID().uuidString,
                      title: "サイトのURL",
                      rightLabel: nil,
                      bottomLabel: clip.url.absoluteString,
                      visibleSeparator: false),
            Item.Cell(id: UUID().uuidString,
                      title: "このクリップを隠す",
                      rightLabel: clip.isHidden ? "はい" : "いいえ",
                      bottomLabel: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: "登録日",
                      rightLabel: "\(clip.registeredDate)",
                      bottomLabel: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: "更新日",
                      rightLabel: "\(clip.updatedDate)",
                      bottomLabel: nil,
                      visibleSeparator: true)
        ].map { .row($0) }
    }

    private static func createCells(for clipItem: ClipItem) -> [Item] {
        return [
            Item.Cell(id: UUID().uuidString,
                      title: "画像のURL",
                      rightLabel: nil,
                      bottomLabel: clipItem.imageUrl.absoluteString,
                      visibleSeparator: false),
            Item.Cell(id: UUID().uuidString,
                      title: "登録日",
                      rightLabel: "\(clipItem.registeredDate)",
                      bottomLabel: nil,
                      visibleSeparator: true),
            Item.Cell(id: UUID().uuidString,
                      title: "更新日",
                      rightLabel: "\(clipItem.updatedDate)",
                      bottomLabel: nil,
                      visibleSeparator: true)
        ].map { .row($0) }
    }
}
