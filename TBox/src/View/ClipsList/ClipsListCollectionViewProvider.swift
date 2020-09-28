//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListCollectionViewProviderDataSource: AnyObject {
    func isEditing(_ provider: ClipsListCollectionViewProvider) -> Bool
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, imageDataAt layer: ThumbnailLayer, in clip: Clip) -> Data?
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, clipFor indexPath: IndexPath) -> Clip?
}

protocol ClipsListCollectionViewProviderDelegate: AnyObject {
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didSelectClip clipId: Clip.Identity)
    func clipsListCollectionViewProvider(_ provider: ClipsListCollectionViewProvider, didDeselectClip clipId: Clip.Identity)
}

class ClipsListCollectionViewProvider: NSObject {
    weak var dataSource: ClipsListCollectionViewProviderDataSource?
    weak var delegate: ClipsListCollectionViewProviderDelegate?

    func provideCell(collectionView: UICollectionView, indexPath: IndexPath, clip: Clip) -> UICollectionViewCell? {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipsCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipsCollectionViewCell else { return dequeuedCell }

        cell.primaryImage = {
            guard let data = self.dataSource?.clipsListCollectionViewProvider(self, imageDataAt: .primary, in: clip) else { return nil }
            return UIImage(data: data)
        }()
        cell.secondaryImage = {
            guard let data = self.dataSource?.clipsListCollectionViewProvider(self, imageDataAt: .secondary, in: clip) else { return nil }
            return UIImage(data: data)
        }()
        cell.tertiaryImage = {
            guard let data = self.dataSource?.clipsListCollectionViewProvider(self, imageDataAt: .tertiary, in: clip) else { return nil }
            return UIImage(data: data)
        }()

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
        self.delegate?.clipsListCollectionViewProvider(self, didSelectClip: clip.identity)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let clip = self.dataSource?.clipsListCollectionViewProvider(self, clipFor: indexPath) else { return }
        self.delegate?.clipsListCollectionViewProvider(self, didDeselectClip: clip.identity)
    }
}

extension ClipsListCollectionViewProvider: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard let clip = self.dataSource?.clipsListCollectionViewProvider(self, clipFor: indexPath) else { return .zero }

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin
                + ClipsCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.thumbnailSize.height) / CGFloat(item.thumbnailSize.width))

        default:
            return width
        }
    }
}
