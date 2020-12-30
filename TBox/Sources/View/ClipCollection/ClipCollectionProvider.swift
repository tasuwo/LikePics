//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import TBoxUIKit
import UIKit

protocol ClipCollectionProviderDataSource: AnyObject {
    func isEditing(_ provider: ClipCollectionProvider) -> Bool
    func clipCollectionProvider(_ provider: ClipCollectionProvider, clipFor indexPath: IndexPath) -> Clip?
    func clipsListCollectionMenuBuilder(_ provider: ClipCollectionProvider) -> ClipCollectionMenuBuildable.Type
    func clipsListCollectionMenuContext(_ provider: ClipCollectionProvider) -> ClipCollection.Context
}

protocol ClipCollectionProviderDelegate: AnyObject {
    func clipCollectionProvider(_ provider: ClipCollectionProvider, didSelect clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, didDeselect clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddTagsTo clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddToAlbum clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldDelete clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldUnhide clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldHide clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldRemoveFromAlbum clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldShare clipId: Clip.Identity, at indexPath: IndexPath)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldPurge clipId: Clip.Identity, at indexPath: IndexPath)
}

class ClipCollectionProvider: NSObject {
    // MARK: - Properties

    weak var dataSource: ClipCollectionProviderDataSource?
    weak var delegate: ClipCollectionProviderDelegate?

    // MARK: ThumbnailRenderable

    let thumbnailLoader: ThumbnailLoader

    // MARK: - Lifecycle

    init(thumbnailLoader: ThumbnailLoader) {
        self.thumbnailLoader = thumbnailLoader
    }

    // MARK: - Methods

    func provideCell(collectionView: UICollectionView, indexPath: IndexPath, clip: Clip) -> UICollectionViewCell? {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipCollectionViewCell else { return dequeuedCell }

        cell.identifier = clip.identity

        let scale = collectionView.traitCollection.displayScale

        if let item = clip.primaryItem {
            let request = self.makeRequest(for: item, size: cell.primaryImageView.bounds.size, scale: scale, context: .primary)
            self.thumbnailLoader.load(request: request, observer: cell)
        } else {
            cell.primaryImage = .noImage
        }
        if let item = clip.secondaryItem {
            let request = self.makeRequest(for: item, size: cell.secondaryImageView.bounds.size, scale: scale, context: .secondary)
            self.thumbnailLoader.load(request: request, observer: cell)
        } else {
            cell.secondaryImage = .noImage
        }
        if let item = clip.tertiaryItem {
            let request = self.makeRequest(for: item, size: cell.tertiaryImageView.bounds.size, scale: scale, context: .tertiary)
            self.thumbnailLoader.load(request: request, observer: cell)
        } else {
            cell.tertiaryImage = .noImage
        }

        cell.visibleSelectedMark = self.dataSource?.isEditing(self) ?? false

        return cell
    }

    private func makeRequest(for item: ClipItem, size: CGSize, scale: CGFloat, context: ClipCollectionViewCell.ThumbnailLoadingUserInfoValue) -> ThumbnailRequest {
        return ThumbnailRequest(identifier: item.clipId,
                                cacheKey: "clip-collection-\(item.identity.uuidString)",
                                originalDataLoadRequest: NewImageDataLoadRequest(imageId: item.imageId),
                                size: size,
                                scale: scale,
                                userInfo: [ClipCollectionViewCell.ThumbnailLoadingUserInfoKey: context.rawValue])
    }
}

extension ClipCollectionProvider: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return false }
        return !cell.isLoading
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ClipCollectionViewCell else { return false }
        return !cell.isLoading
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource?.clipCollectionProvider(self, clipFor: indexPath) else { return }
        self.delegate?.clipCollectionProvider(self, didSelect: clip.identity)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource?.clipCollectionProvider(self, clipFor: indexPath) else { return }
        self.delegate?.clipCollectionProvider(self, didDeselect: clip.identity)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard
            let clip = self.dataSource?.clipCollectionProvider(self, clipFor: indexPath),
            self.dataSource?.isEditing(self) == false
        else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath,
                                          previewProvider: nil,
                                          actionProvider: self.makeActionProvider(for: clip, at: indexPath))
    }

    func collectionView(_ collectionView: UICollectionView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return self.makeTargetedPreview(for: configuration, collectionView: collectionView)
    }

    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration, collectionView: UICollectionView) -> UITargetedPreview? {
        guard let identifier = configuration.identifier as? NSIndexPath else { return nil }
        guard let cell = collectionView.cellForItem(at: identifier as IndexPath) else { return nil }
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = .clear
        return UITargetedPreview(view: cell, parameters: parameters)
    }

    private func makeActionProvider(for clip: Clip, at indexPath: IndexPath) -> UIContextMenuActionProvider {
        guard let dataSource = self.dataSource else { return { _ in return UIMenu() } }

        let builder = dataSource.clipsListCollectionMenuBuilder(self)
        let context = dataSource.clipsListCollectionMenuContext(self)

        let items = builder.build(for: clip, context: context).map {
            self.makeAction(from: $0, for: clip, at: indexPath)
        }

        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeAction(from item: ClipCollection.MenuItem, for clip: Clip, at indexPath: IndexPath) -> UIAction {
        switch item {
        case .addTag:
            return UIAction(title: L10n.clipsListContextMenuAddTag,
                            image: UIImage(systemName: "tag.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.delegate?.clipCollectionProvider(self, shouldAddTagsTo: clip.identity, at: indexPath)
                }
            }

        case .addToAlbum:
            return UIAction(title: L10n.clipsListContextMenuAddToAlbum,
                            image: UIImage(systemName: "rectangle.stack.fill.badge.plus")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.delegate?.clipCollectionProvider(self, shouldAddToAlbum: clip.identity, at: indexPath)
                }
            }

        case .unhide:
            return UIAction(title: L10n.clipsListContextMenuUnhide,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldUnhide: clip.identity, at: indexPath)
                }
            }

        case .hide:
            return UIAction(title: L10n.clipsListContextMenuHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldHide: clip.identity, at: indexPath)
                }
            }

        case .removeFromAlbum:
            return UIAction(title: L10n.clipsListContextMenuRemoveFromAlbum,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldRemoveFromAlbum: clip.identity, at: indexPath)
                }
            }

        case .delete:
            return UIAction(title: L10n.clipsListContextMenuDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldDelete: clip.identity, at: indexPath)
                }
            }

        case .share:
            return UIAction(title: L10n.clipsListContextMenuShare,
                            image: UIImage(systemName: "square.and.arrow.up.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldShare: clip.identity, at: indexPath)
                }
            }

        case .purge:
            return UIAction(title: L10n.clipsListContextMenuPurge,
                            image: UIImage(systemName: "scissors")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldPurge: clip.identity, at: indexPath)
                }
            }
        }
    }
}

extension ClipCollectionProvider: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard let clip = self.dataSource?.clipCollectionProvider(self, clipFor: indexPath) else { return .zero }

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipCollectionViewCell.secondaryStickingOutMargin
                + ClipCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        default:
            return width
        }
    }
}

extension ClipCollectionProvider: UICollectionViewDataSourcePrefetching {
    // MARK: - UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let layout = collectionView.collectionViewLayout as? ClipCollectionLayout else { return }
        for indexPath in indexPaths {
            guard let attribute = layout.layoutAttributesForItem(at: indexPath) else { return }
            guard let clip = self.dataSource?.clipCollectionProvider(self, clipFor: indexPath) else { return }
            let scale = collectionView.traitCollection.displayScale
            if let item = clip.primaryItem {
                let request = self.makeRequest(for: item, size: attribute.frame.size, scale: scale, context: .primary)
                self.thumbnailLoader.load(request: request, observer: nil)
            }
            if let item = clip.secondaryItem {
                let request = self.makeRequest(for: item, size: attribute.frame.size, scale: scale, context: .secondary)
                self.thumbnailLoader.load(request: request, observer: nil)
            }
            if let item = clip.tertiaryItem {
                let request = self.makeRequest(for: item, size: attribute.frame.size, scale: scale, context: .tertiary)
                self.thumbnailLoader.load(request: request, observer: nil)
            }
        }
    }
}
