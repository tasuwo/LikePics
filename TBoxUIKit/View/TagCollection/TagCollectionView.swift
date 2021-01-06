//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class TagCollectionView: UICollectionView {
    public static let interItemSpacing: CGFloat = 8

    public enum CellType {
        case addition
        case tag

        var identifier: String {
            switch self {
            case .addition:
                return "tag-addition"

            case .tag:
                return "tag"
            }
        }
    }

    public enum CellConfiguration {
        public struct Addition {
            public let title: String
            public weak var delegate: ButtonCellDelegate?

            public init(title: String, delegate: ButtonCellDelegate?) {
                self.title = title
                self.delegate = delegate
            }
        }

        public struct Tag {
            public let tag: Domain.Tag
            public let displayMode: TagCollectionViewCell.DisplayMode
            public let visibleDeleteButton: Bool
            public let visibleCountIfPossible: Bool
            public weak var delegate: TagCollectionViewCellDelegate?

            public init(tag: Domain.Tag,
                        displayMode: TagCollectionViewCell.DisplayMode,
                        visibleDeleteButton: Bool,
                        visibleCountIfPossible: Bool,
                        delegate: TagCollectionViewCellDelegate?)
            {
                self.tag = tag
                self.displayMode = displayMode
                self.visibleDeleteButton = visibleDeleteButton
                self.visibleCountIfPossible = visibleCountIfPossible
                self.delegate = delegate
            }
        }

        case addition(Addition)
        case tag(Self.Tag)

        var type: CellType {
            switch self {
            case .addition:
                return .addition

            case .tag:
                return .tag
            }
        }
    }

    // MARK: - Lifecycle

    override public init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)

        self.registerCell()
        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.registerCell()
        self.setupAppearance()
    }

    // MARK: - Methods

    public static func provideCell(collectionView: UICollectionView,
                                   indexPath: IndexPath,
                                   configuration: CellConfiguration) -> UICollectionViewCell?
    {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: configuration.type.identifier,
                                                              for: indexPath)

        switch configuration {
        case let .addition(config):
            guard let cell = dequeuedCell as? ButtonCell else { return dequeuedCell }

            cell.title = config.title
            cell.delegate = config.delegate

            return cell

        case let .tag(config):
            guard let cell = dequeuedCell as? TagCollectionViewCell else { return dequeuedCell }

            cell.title = config.tag.name
            cell.displayMode = config.displayMode
            cell.visibleCountIfPossible = config.visibleCountIfPossible
            if let clipCount = config.tag.clipCount {
                cell.count = clipCount
            }
            cell.visibleDeleteButton = config.visibleDeleteButton
            cell.delegate = config.delegate

            return cell
        }
    }

    public static func createLayoutSection(groupEdgeSpacing: NSCollectionLayoutEdgeSpacing? = nil,
                                           groupContentInsets: NSDirectionalEdgeInsets? = nil) -> NSCollectionLayoutSection
    {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(36),
                                              heightDimension: .estimated(32))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(0),
                                                         top: nil,
                                                         trailing: .fixed(Self.interItemSpacing),
                                                         bottom: nil)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(32))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        if let edgeSpacing = groupEdgeSpacing {
            group.edgeSpacing = edgeSpacing
        }

        if let contentInsets = groupContentInsets {
            group.contentInsets = contentInsets
        }

        return NSCollectionLayoutSection(group: group)
    }

    private func registerCell() {
        self.register(TagCollectionViewCell.nib, forCellWithReuseIdentifier: CellType.tag.identifier)
        self.register(ButtonCell.nib, forCellWithReuseIdentifier: CellType.addition.identifier)
    }

    private func setupAppearance() {
        self.allowsSelection = true
        self.allowsMultipleSelection = true
    }
}
