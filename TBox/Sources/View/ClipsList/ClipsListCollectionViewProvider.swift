//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListCollectionViewProviderDataSource: AnyObject {
    func isEditing(_ provider: ClipsListCollectionViewProvider) -> Bool
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, clipFor indexPath: IndexPath) -> Clip?
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, imageFor clipItem: ClipItem) -> UIImage?
    func requestImage(_ provider: ClipsListCollectionViewProvider, for clipItem: ClipItem, completion: @escaping (UIImage?) -> Void)
}

protocol ClipsListCollectionViewProviderDelegate: AnyObject {
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didSelect clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didDeselect clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldAddTagsTo clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldAddToAlbum clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldDelete clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldUnhide clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, shouldHide clipId: Clip.Identity)
}

class ClipsListCollectionViewProvider: NSObject {
    weak var dataSource: ClipsListCollectionViewProviderDataSource?
    weak var delegate: ClipsListCollectionViewProviderDelegate?

    func provideCell(collectionView: UICollectionView, indexPath: IndexPath, clip: Clip) -> UICollectionViewCell? {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipsCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipsCollectionViewCell else { return dequeuedCell }

        cell.identifier = clip.identity

        cell.secondaryImage = nil
        cell.tertiaryImage = nil

        if let item = clip.primaryItem {
            if let image = self.dataSource?.clipsListCollectionViewProvider(self, imageFor: item) {
                cell.primaryImage = image
            } else {
                cell.primaryImage = nil
                self.dataSource?.requestImage(self, for: item) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == clip.identity else { return }
                        cell.primaryImage = image
                    }
                }
            }
        } else {
            cell.primaryImage = nil
        }

        if let item = clip.secondaryItem {
            if let image = self.dataSource?.clipsListCollectionViewProvider(self, imageFor: item) {
                cell.secondaryImage = image
            } else {
                cell.secondaryImage = nil
                self.dataSource?.requestImage(self, for: item) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == clip.identity else { return }
                        cell.secondaryImage = image
                    }
                }
            }
        } else {
            cell.secondaryImage = nil
        }

        if let item = clip.tertiaryItem {
            if let image = self.dataSource?.clipsListCollectionViewProvider(self, imageFor: item) {
                cell.tertiaryImage = image
            } else {
                cell.tertiaryImage = nil
                self.dataSource?.requestImage(self, for: item) { image in
                    DispatchQueue.main.async {
                        guard cell.identifier == clip.identity else { return }
                        cell.tertiaryImage = image
                    }
                }
            }
        } else {
            cell.tertiaryImage = nil
        }

        cell.visibleSelectedMark = self.dataSource?.isEditing(self) ?? false

        return cell
    }
}

extension ClipsListCollectionViewProvider: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource?.clipsListCollectionViewProvider(self, clipFor: indexPath) else { return }
        self.delegate?.clipsListCollectionViewProvider(self, didSelect: clip.identity)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource?.clipsListCollectionViewProvider(self, clipFor: indexPath) else { return }
        self.delegate?.clipsListCollectionViewProvider(self, didDeselect: clip.identity)
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard
            let clip = self.dataSource?.clipsListCollectionViewProvider(self, clipFor: indexPath),
            self.dataSource?.isEditing(self) == false
        else {
            return nil
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: self.makeActionProvider(for: clip))
    }

    private func makeActionProvider(for clip: Clip) -> UIContextMenuActionProvider {
        let addTag = UIAction(title: L10n.clipsListContextMenuAddTag,
                              image: UIImage(systemName: "tag.fill")) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.delegate?.clipsListCollectionViewProvider(self, shouldAddTagsTo: clip.identity)
            }
        }
        let addToAlbum = UIAction(title: L10n.clipsListContextMenuAddToAlbum,
                                  image: UIImage(systemName: "rectangle.stack.fill.badge.plus")) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.delegate?.clipsListCollectionViewProvider(self, shouldAddToAlbum: clip.identity)
            }
        }

        let hideAction: UIAction
        if clip.isHidden {
            hideAction = UIAction(title: L10n.clipsListContextMenuUnhide,
                                  image: UIImage(systemName: "eye.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipsListCollectionViewProvider(self, shouldUnhide: clip.identity)
                }
            }
        } else {
            hideAction = UIAction(title: L10n.clipsListContextMenuHide,
                                  image: UIImage(systemName: "eye.slash.fill")) { [weak self] _ in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.delegate?.clipsListCollectionViewProvider(self, shouldHide: clip.identity)
                }
            }
        }

        let delete = UIAction(title: L10n.clipsListContextMenuDelete,
                              image: UIImage(systemName: "trash.fill"),
                              attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.delegate?.clipsListCollectionViewProvider(self, shouldDelete: clip.identity)
            }
        }

        return { _ in
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [
                addTag,
                addToAlbum,
                hideAction,
                delete
            ])
        }
    }
}

extension ClipsListCollectionViewProvider: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard let clip = self.dataSource?.clipsListCollectionViewProvider(self, clipFor: indexPath) else { return .zero }

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin
                + ClipsCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.imageSize.height) / CGFloat(item.imageSize.width))

        default:
            return width
        }
    }
}
