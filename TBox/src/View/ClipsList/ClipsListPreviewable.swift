//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipsListPreviewable: ClipsListDisplayable where Presenter: ClipsListPreviewablePresenter {}

extension ClipsListPreviewable where Self: UICollectionViewDelegate {
    // MARK: - UICollectionViewDelegate

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ displayable: Self, _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let clip = self.presenter.select(at: indexPath.row) else { return }
        let nextViewController = self.factory.makeClipPreviewViewController(clip: clip)
        self.present(nextViewController, animated: true, completion: nil)
    }
}
