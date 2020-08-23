//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipPreviewPresentingViewController: UIViewController {
    var collectionView: ClipsCollectionView! { get }
    var selectedIndexPath: IndexPath? { get }
    var clips: [Clip] { get }
}

extension ClipPreviewPresentingViewController where Self: ClipsListDisplayable {
    var selectedIndexPath: IndexPath? {
        guard let index = self.presenter.selectedIndex else { return nil }
        return IndexPath(row: index, section: 0)
    }

    var clips: [Clip] {
        return self.presenter.clips
    }
}
