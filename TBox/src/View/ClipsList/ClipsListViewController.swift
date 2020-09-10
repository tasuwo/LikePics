//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListViewController: UIViewController {
    associatedtype Presenter: ClipsListPresenterProtocol

    typealias Factory = ViewControllerFactory

    var factory: Factory { get }
    var presenter: Presenter { get }

    var collectionView: ClipsCollectionView! { get }
}

extension ClipsListViewController {
    func updateCollectionView(for editing: Bool) {
        self.collectionView.allowsMultipleSelection = editing
        self.collectionView.visibleCells
            .compactMap { $0 as? ClipsCollectionViewCell }
            .forEach { $0.visibleSelectedMark = editing }
    }
}

extension ClipsListViewController where Self: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.presenter.select(at: indexPath.row)
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.presenter.deselect(at: indexPath.row)
    }
}

extension ClipsListViewController where Self: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource

    func numberOfSections(_ displayable: Self, in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.presenter.clips.count
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let dequeuedCell = collectionView.dequeueReusableCell(withReuseIdentifier: ClipsCollectionView.cellIdentifier, for: indexPath)
        guard let cell = dequeuedCell as? ClipsCollectionViewCell else { return dequeuedCell }
        guard self.presenter.clips.indices.contains(indexPath.row) else { return cell }

        let clip = self.presenter.clips[indexPath.row]
        cell.primaryImage = {
            guard let data = self.presenter.getImageData(for: .primary, in: clip) else { return nil }
            return UIImage(data: data)
        }()
        cell.secondaryImage = {
            guard let data = self.presenter.getImageData(for: .secondary, in: clip) else { return nil }
            return UIImage(data: data)
        }()
        cell.tertiaryImage = {
            guard let data = self.presenter.getImageData(for: .tertiary, in: clip) else { return nil }
            return UIImage(data: data)
        }()

        cell.visibleSelectedMark = self.presenter.isEditing

        return cell
    }
}

extension ClipsListViewController where Self: ClipsCollectionLayoutDelegate {
    // MARK: - ClipsCollectionLayoutDelegate

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, photoHeightForWidth width: CGFloat, atIndexPath indexPath: IndexPath) -> CGFloat {
        guard self.presenter.clips.indices.contains(indexPath.row) else { return .zero }
        let clip = self.presenter.clips[indexPath.row]

        switch (clip.primaryItem, clip.secondaryItem, clip.tertiaryItem) {
        case let (.some(item), .none, .none):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))

        case let (.some(item), .some, .none):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin

        case let (.some(item), .some, .some):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))
                + ClipsCollectionViewCell.secondaryStickingOutMargin
                + ClipsCollectionViewCell.tertiaryStickingOutMargin

        case let (.some(item), _, _):
            return width * (CGFloat(item.thumbnail.size.height) / CGFloat(item.thumbnail.size.width))

        default:
            return width
        }
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, heightForHeaderAtIndexPath indexPath: IndexPath) -> CGFloat {
        return .zero
    }
}
