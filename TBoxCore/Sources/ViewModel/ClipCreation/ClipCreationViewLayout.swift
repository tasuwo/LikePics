//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import Smoothie
import TBoxUIKit
import UIKit

enum ClipCreationViewLayout {
    typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>

    enum Section: Int {
        // case url
        case tag
        case image
    }

    enum Item: Hashable {
        // case urlAddition
        // case url(URL)
        case tagAddition
        case tag(Tag)
        case image(ImageSource)

        var identifier: String {
            switch self {
            // case .urlAddition:
            //     return "url-addition"

            // case .url:
            //     return "url"

            case .tagAddition:
                return "tag-addition"

            case let .tag(tag):
                return tag.id.uuidString

            case let .image(source):
                return source.identifier.uuidString
            }
        }
    }
}

// MARK: - Layout

extension ClipCreationViewLayout {
    static func predictCellSize(for collectionView: UICollectionView) -> CGSize {
        let numberOfColumns: CGFloat = {
            switch collectionView.traitCollection.horizontalSizeClass {
            case .compact:
                return 2

            case .regular, .unspecified:
                return 3

            @unknown default:
                return 3
            }
        }()
        let totalSpaceSize: CGFloat = 16 * 2 + (numberOfColumns - 1) * 16
        let width = (collectionView.bounds.size.width - totalSpaceSize) / numberOfColumns
        return CGSize(width: width, height: width)
    }

    static func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, environment -> NSCollectionLayoutSection? in
            switch Section(rawValue: sectionIndex) {
            // case .url:
            //     return self.createUrlLayoutSection()

            case .tag:
                return self.createTagsLayoutSection()

            case .image:
                return self.createImageLayoutSection(for: environment)

            case .none:
                return nil
            }
        }
        return layout
    }

    private static func createUrlLayoutSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(32))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 0, trailing: 16)

        return section
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)

        return section
    }
}

// MARK: - DataSource

extension ClipCreationViewLayout {
    static func createSnapshot(url: URL?, tags: [Tag], images: [ImageSource]) -> Snapshot {
        var snapshot = Snapshot()
        // snapshot.appendSections([.url])
        // if let url = url {
        //     snapshot.appendItems([.url(url)])
        // } else {
        //     snapshot.appendItems([.urlAddition])
        // }
        snapshot.appendSections([.tag])
        snapshot.appendItems([Item.tagAddition] + tags.map({ Item.tag($0) }))
        snapshot.appendSections([.image])
        snapshot.appendItems(images.map({ Item.image($0) }))
        return snapshot
    }

    static func configureDataSource(collectionView: UICollectionView,
                                    buttonCellDelegate: ButtonCellDelegate,
                                    tagCellDelegate: TagCollectionViewCellDelegate,
                                    thumbnailLoader: Smoothie.ThumbnailLoader,
                                    outputs: ClipCreationViewModelOutputs) -> DataSource
    {
        let urlAdditionCellRegistration = UICollectionView.CellRegistration<ButtonCell, Void>(cellNib: ButtonCell.nib) { [weak buttonCellDelegate] cell, _, _ in
            cell.title = L10n.clipCreationViewUrlAdditionCellTitle
            cell.delegate = buttonCellDelegate
        }

        let urlCellRegistration = UICollectionView.CellRegistration<ButtonCell, URL>(cellNib: ButtonCell.nib) { [weak buttonCellDelegate] cell, _, url in
            cell.title = url.absoluteString
            cell.delegate = buttonCellDelegate
        }

        let tagAdditionCellRegistration = UICollectionView.CellRegistration<ButtonCell, Void>(cellNib: ButtonCell.nib) { [weak buttonCellDelegate] cell, _, _ in
            cell.title = L10n.clipCreationViewTagAdditionCellTitle
            cell.delegate = buttonCellDelegate
        }

        let tagCellRegistration = UICollectionView.CellRegistration<TagCollectionViewCell, Tag>(cellNib: TagCollectionViewCell.nib) { [weak tagCellDelegate] cell, _, tag in
            cell.title = tag.name
            cell.displayMode = .normal
            cell.visibleCountIfPossible = false
            cell.visibleDeleteButton = true
            cell.delegate = tagCellDelegate
            cell.isHiddenTag = tag.isHidden
        }

        let imageCellRegistration = UICollectionView.CellRegistration<ClipSelectionCollectionViewCell, ImageSource>(cellNib: ClipSelectionCollectionViewCell.nib) { [weak thumbnailLoader, weak outputs] cell, indexPath, source in
            let requestId = UUID().uuidString
            cell.identifier = requestId
            cell.image = nil

            let info = ThumbnailRequest.ThumbnailInfo(id: "clip-creation-\(source.identifier.uuidString)",
                                                      size: cell.imageDisplaySize,
                                                      scale: cell.traitCollection.displayScale)
            let request = ThumbnailRequest(requestId: requestId,
                                           originalImageRequest: source,
                                           thumbnailInfo: info)
            thumbnailLoader?.load(request: request, observer: cell)

            // モデルにIndexを含めることも検討したが、選択状態更新毎にDataSourceを更新させると見た目がイマイチだったため、
            // selectionOrderについてはPushではなくPull方式を取る
            if let indexInSelection = outputs?.selectedIndices.value.firstIndex(of: indexPath.row) {
                cell.selectionOrder = indexInSelection + 1
            }
        }

        return .init(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            // case .urlAddition:
            //     return collectionView.dequeueConfiguredReusableCell(using: urlAdditionCellRegistration, for: indexPath, item: ())

            // case let .url(url):
            //     return collectionView.dequeueConfiguredReusableCell(using: urlCellRegistration, for: indexPath, item: url)

            case .tagAddition:
                return collectionView.dequeueConfiguredReusableCell(using: tagAdditionCellRegistration, for: indexPath, item: ())

            case let .tag(tag):
                return collectionView.dequeueConfiguredReusableCell(using: tagCellRegistration, for: indexPath, item: tag)

            case let .image(source):
                return collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: source)
            }
        }
    }
}
