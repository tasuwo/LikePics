//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain
import LikePicsUIKit
import UIKit

enum ClipPreviewPlayConfigurationModalLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        case main
    }

    enum Item: CaseIterable, Equatable {
        case interval
        case loop
        case animation
        case order
        case range
    }
}

// MARK: - Layout

extension ClipPreviewPlayConfigurationModalLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { _, environment -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            configuration.backgroundColor = Asset.Color.background.color
            return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        }
        return layout
    }
}

// MARK: - DataSource

extension ClipPreviewPlayConfigurationModalLayout {
    static func configureDataSource(collectionView: UICollectionView,
                                    storage: ClipPreviewPlayConfigurationStorageProtocol,
                                    onUpdateLoop: @escaping (Bool) -> Void,
                                    onIntervalEdit: @escaping () -> Void) -> DataSource
    {
        let cellRegistration = configureCell(storage: storage, onUpdateLoop: onUpdateLoop, onIntervalEdit: onIntervalEdit)

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }

        return dataSource
    }

    private static func configureCell(storage: ClipPreviewPlayConfigurationStorageProtocol,
                                      onUpdateLoop: @escaping (Bool) -> Void,
                                      onIntervalEdit: @escaping () -> Void) -> UICollectionView.CellRegistration<UICollectionViewListCell, Item>
    {
        return UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = item.displayText
            switch item {
            case .animation:
                contentConfiguration.secondaryText = storage.fetchAnimation().displayText

            case .order:
                contentConfiguration.secondaryText = storage.fetchOrder().displayText

            case .range:
                contentConfiguration.secondaryText = storage.fetchRange().displayText

            case .interval:
                contentConfiguration.secondaryText = L10n.Root.MenuItemInterval.seconds(storage.fetchInterval())

            default:
                contentConfiguration.secondaryText = nil
            }
            cell.contentConfiguration = contentConfiguration

            switch item {
            case .loop:
                let `switch` = UISwitch()
                `switch`.isOn = storage.fetchLoopEnabled()
                `switch`.addAction(.init(handler: { action in
                    guard let `switch` = action.sender as? UISwitch else { return }
                    onUpdateLoop(`switch`.isOn)
                }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: `switch`, placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]

            case .animation, .order, .range:
                cell.accessories = [.disclosureIndicator()]

            case .interval:
                let editButton = UIButton(type: .system)
                editButton.setTitle(L10n.Root.MenuItemInterval.editButton, for: .normal)
                editButton.addAction(.init(handler: { _ in onIntervalEdit() }), for: .touchUpInside)
                let configuration = UICellAccessory.CustomViewConfiguration(customView: editButton, placement: .trailing(displayed: .always))
                cell.accessories = [.customView(configuration: configuration)]
            }

            var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfiguration.backgroundColor = Asset.Color.secondaryBackground.color
            cell.backgroundConfiguration = backgroundConfiguration
        }
    }
}

extension ClipPreviewPlayConfigurationModalLayout.Item {
    var displayText: String {
        switch self {
        case .animation:
            return L10n.Root.MenuTitle.animation
        case .order:
            return L10n.Root.MenuTitle.order
        case .range:
            return L10n.Root.MenuTitle.range
        case .loop:
            return L10n.Root.MenuTitle.loop
        case .interval:
            return L10n.Root.MenuTitle.interval
        }
    }
}
