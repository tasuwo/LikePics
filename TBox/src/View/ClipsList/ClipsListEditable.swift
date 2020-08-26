//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListEditable: ClipsListDisplayable where Presenter: ClipsListEditablePresenter {}

extension ClipsListEditable {
    func didTapAddButton() {
        self.presenter.addAllToAlbum()
    }

    func didTapRemoveButton() {
        let alert = UIAlertController(title: "", message: "選択中の画像を全て削除しますか？", preferredStyle: .alert)

        alert.addAction(.init(title: "削除", style: .destructive, handler: { [weak self] _ in
            self?.presenter.deleteAll()
        }))
        alert.addAction(.init(title: "キャンセル", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }
}

extension ClipsListEditable where Self: UICollectionViewDelegate {
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

extension ClipsListEditable where Self: UICollectionViewDataSource {
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
            return UIImage(data: data)!
        }()
        cell.secondaryImage = {
            guard let data = self.presenter.getImageData(for: .secondary, in: clip) else { return nil }
            return UIImage(data: data)!
        }()
        cell.tertiaryImage = {
            guard let data = self.presenter.getImageData(for: .tertiary, in: clip) else { return nil }
            return UIImage(data: data)!
        }()

        cell.visibleSelectedMark = true

        return cell
    }
}
