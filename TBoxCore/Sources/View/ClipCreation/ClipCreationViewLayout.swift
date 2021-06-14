//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

public protocol ClipCreationViewDelegate: AnyObject {
    func didTapButton(_ cell: UICollectionViewCell, at indexPath: IndexPath)
    func didSwitchHiding(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool)
    func didTapTagAdditionButton(_ cell: UICollectionViewCell)
    func didTapTagDeletionButton(_ cell: UICollectionViewCell)
}

public protocol ImageSourcesProvider: AnyObject {
    var imageSources: [UUID: ImageSource] { get }
    func selectionOrder(of id: UUID) -> Int?
}

public enum ClipCreationViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    public typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    public enum Section: Int {
        case tag
        case meta
        case image
    }

    public enum Item: Hashable {
        case tagAddition
        case tag(Tag)
        case meta(Info)
        case image(UUID)
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

// MARK: - Layout

extension ClipCreationViewLayout {
    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            case .tag:
                return self.createTagsLayoutSection()

            case .meta:
                var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
                configuration.backgroundColor = Asset.Color.background.color
                return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)

            case .image:
                return self.createImageLayoutSection(for: environment)

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
        section.contentInsets = NSDirectionalEdgeInsets(top: 24, leading: 20, bottom: 5, trailing: 20)

        return section
    }

    private static func createImageLayoutSection(for environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let count: Int = {
            switch environment.traitCollection.horizontalSizeClass {
            case .compact:
                return 2

            case .regular, .unspecified:
                return 3

            @unknown default:
                return 3
            }
        }()
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(1 / CGFloat(count)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        group.interItemSpacing = .fixed(16)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = CGFloat(16)
        section.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 20, bottom: 10, trailing: 20)

        return section
    }
}

// MARK: - DataSource

extension ClipCreationViewLayout {
    class Proxy {
        weak var delegate: ClipCreationViewDelegate?
    }

    static func configureDataSource(collectionView: UICollectionView,
                                    imageSourcesProvider: ImageSourcesProvider,
                                    thumbnailLoader: Smoothie.ThumbnailLoaderProtocol) -> (Proxy, DataSource)
    {
        let proxy = Proxy()

        let tagAdditionCellRegistration = self.configureTagAdditionCell(delegate: proxy)
        let tagCellRegistration = self.configureTagCell(delegate: proxy)
        let metaCellRegistration = self.configureMetaCell(proxy: proxy)
        let imageCellRegistration = self.configureImageCell(imageSourcesProvider: imageSourcesProvider, thumbnailLoader: thumbnailLoader)

        let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case let .meta(info):
                return collectionView.dequeueConfiguredReusableCell(using: metaCellRegistration, for: indexPath, item: info)

            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .image(source):
                return collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: source)
            }
        }

        return (proxy, dataSource)
    }

    private static func configureTagAdditionCell(delegate: ButtonCellDelegate) -> UICollectionView.CellRegistration<ButtonCell, Void> {
        return UICollectionView.CellRegistration<ButtonCell, Void>(cellNib: ButtonCell.nib) { [weak delegate] cell, _, _ in
            cell.title = L10n.clipCreationViewTagAdditionCellTitle
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
            cell.contentConfiguration = contentConfiguration

            switch info.accessory {
            case let .button(title: title):
                let button = UIButton()
                button.setTitle(title, for: .normal)
                button.setTitleColor(button.tintColor, for: .normal)
                button.addAction(.init(handler: { [weak proxy] _ in
                    proxy?.didTapButton(cell, at: indexPath)
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
                    proxy?.didSwitchInfo(cell, at: indexPath, isOn: sw.isOn)
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

    private static func configureImageCell(imageSourcesProvider: ImageSourcesProvider,
                                           thumbnailLoader: ThumbnailLoaderProtocol) -> UICollectionView.CellRegistration<ClipSelectionCollectionViewCell, UUID>
    {
        return .init(cellNib: ClipSelectionCollectionViewCell.nib) { [weak imageSourcesProvider, weak thumbnailLoader] cell, _, imageSourceId in
            guard let imageSourcesProvider = imageSourcesProvider,
                  let imageSource = imageSourcesProvider.imageSources[imageSourceId] else { return }

            let requestId = UUID().uuidString
            cell.identifier = requestId
            cell.image = nil

            // Note: サイズ取得をこのタイミングで行うと重いため、行わない
            let size = cell.calcThumbnailPointSize(originalPixelSize: nil)
            let info = ThumbnailConfig(cacheKey: "clip-creation-\(imageSourceId.uuidString)",
                                       size: size,
                                       scale: cell.traitCollection.displayScale)
            let request = ThumbnailRequest(requestId: requestId,
                                           originalImageRequest: imageSource,
                                           config: info)
            thumbnailLoader?.load(request, observer: cell)

            // モデルにIndexを含めることも検討したが、選択状態更新毎にDataSourceを更新させると見た目がイマイチだったため、
            // selectionOrderについてはPushではなくPull方式を取る
            if let index = imageSourcesProvider.selectionOrder(of: imageSourceId) {
                cell.selectionOrder = index + 1
            }
        }
    }
}

// MARK: - Proxy

extension ClipCreationViewLayout.Proxy {
    func didSwitchInfo(_ cell: UICollectionViewCell, at indexPath: IndexPath, isOn: Bool) {
        self.delegate?.didSwitchHiding(cell, at: indexPath, isOn: isOn)
    }

    func didTapButton(_ cell: UICollectionViewCell, at indexPath: IndexPath) {
        self.delegate?.didTapButton(cell, at: indexPath)
    }
}

extension ClipCreationViewLayout.Proxy: ButtonCellDelegate {
    // MARK: - ButtonCellDelegate

    func didTap(_ cell: ButtonCell) {
        self.delegate?.didTapTagAdditionButton(cell)
    }
}

extension ClipCreationViewLayout.Proxy: TagCollectionViewCellDelegate {
    // MARK: - TagCollectionViewCellDelegate

    func didTapDeleteButton(_ cell: TagCollectionViewCell) {
        self.delegate?.didTapTagDeletionButton(cell)
    }
}
