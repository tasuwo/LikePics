//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipCollectionProviderDataSource: AnyObject {
    func isEditing(_ provider: ClipCollectionProvider) -> Bool
    func clipCollectionProvider(_ provider: ClipCollectionProvider, clipFor indexPath: IndexPath) -> Clip?
    func clipCollectionProvider(_ provider: ClipCollectionProvider, imageFor clipItem: ClipItem) -> UIImage?
    func requestImage(_ provider: ClipCollectionProvider, for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void)
    func clipsListCollectionMenuBuilder(_ provider: ClipCollectionProvider) -> ClipCollectionMenuBuildable.Type
    func clipsListCollectionMenuContext(_ provider: ClipCollectionProvider) -> ClipCollection.Context
}

protocol ClipCollectionProviderDelegate: AnyObject {
    func clipCollectionProvider(_ provider: ClipCollectionProvider, didSelect clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, didDeselect clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddTagsTo clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldAddToAlbum clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldDelete clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldUnhide clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldHide clipId: Clip.Identity)
    func clipCollectionProvider(_ provider: ClipCollectionProvider, shouldRemoveFromAlbum clipId: Clip.Identity)
}

class ClipCollectionProvider: NSObject {
    weak var dataSource: ClipCollectionProviderDataSource?
    weak var delegate: ClipCollectionProviderDelegate?

    func provideCell(collectionView: UICollectionView, indexPath: IndexPath, clip: Clip) -> UICollectionViewCell? {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipCollectionViewCell else { return dequeuedCell }

        cell.identifier = clip.identity

        cell.secondaryImage = nil
        cell.tertiaryImage = nil

        if let item = clip.primaryItem {
            if let image = self.dataSource?.clipCollectionProvider(self, imageFor: item) {
                cell.primaryImage = .loaded(image)
            } else {
                cell.primaryImage = .loading
                self.dataSource?.requestImage(self, for: item) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == clip.identity else { return }
                        if let image = image {
                            cell.primaryImage = .loaded(image)
                        } else {
                            cell.primaryImage = .failedToLoad
                        }
                    }
                }
            }
        } else {
            cell.primaryImage = .noImage
        }

        if let item = clip.secondaryItem {
            if let image = self.dataSource?.clipCollectionProvider(self, imageFor: item) {
                cell.secondaryImage = .loaded(image)
            } else {
                cell.secondaryImage = .loading
                self.dataSource?.requestImage(self, for: item) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == clip.identity else { return }
                        if let image = image {
                            cell.secondaryImage = .loaded(image)
                        } else {
                            cell.secondaryImage = .failedToLoad
                        }
                    }
                }
            }
        } else {
            cell.secondaryImage = .noImage
        }

        if let item = clip.tertiaryItem {
            if let image = self.dataSource?.clipCollectionProvider(self, imageFor: item) {
                cell.tertiaryImage = .loaded(image)
            } else {
                cell.tertiaryImage = .loading
                self.dataSource?.requestImage(self, for: item) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == clip.identity else { return }
                        if let image = image {
                            cell.tertiaryImage = .loaded(image)
                        } else {
                            cell.tertiaryImage = .failedToLoad
                        }
                    }
                }
            }
        } else {
            cell.tertiaryImage = .noImage
        }

        cell.visibleSelectedMark = self.dataSource?.isEditing(self) ?? false

        return cell
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
        return UIContextMenuConfiguration(identifier: indexPath as NSIndexPath, previewProvider: nil, actionProvider: self.makeActionProvider(for: clip))
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

    private func makeActionProvider(for clip: Clip) -> UIContextMenuActionProvider {
        guard let dataSource = self.dataSource else { return { _ in return UIMenu() } }

        let builder = dataSource.clipsListCollectionMenuBuilder(self)
        let context = dataSource.clipsListCollectionMenuContext(self)

        let items = builder.build(for: clip, context: context).map {
            self.makeAction(from: $0, for: clip)
        }

        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
        }
    }

    private func makeAction(from item: ClipCollection.MenuItem, for clip: Clip) -> UIAction {
        switch item {
        case .addTag:
            return UIAction(title: L10n.clipsListContextMenuAddTag,
                            image: UIImage(systemName: "tag.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.delegate?.clipCollectionProvider(self, shouldAddTagsTo: clip.identity)
                }
            }

        case .addToAlbum:
            return UIAction(title: L10n.clipsListContextMenuAddToAlbum,
                            image: UIImage(systemName: "rectangle.stack.fill.badge.plus")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.delegate?.clipCollectionProvider(self, shouldAddToAlbum: clip.identity)
                }
            }

        case .unhide:
            return UIAction(title: L10n.clipsListContextMenuUnhide,
                            image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldUnhide: clip.identity)
                }
            }

        case .hide:
            return UIAction(title: L10n.clipsListContextMenuHide,
                            image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldHide: clip.identity)
                }
            }

        case .removeFromAlbum:
            return UIAction(title: L10n.clipsListContextMenuRemoveFromAlbum,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldRemoveFromAlbum: clip.identity)
                }
            }

        case .delete:
            return UIAction(title: L10n.clipsListContextMenuDelete,
                            image: UIImage(systemName: "trash.fill"),
                            attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipCollectionProvider(self, shouldDelete: clip.identity)
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
