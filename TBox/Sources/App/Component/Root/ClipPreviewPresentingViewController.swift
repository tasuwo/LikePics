//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import TBoxUIKit
import UIKit

protocol ClipPreviewPresentingViewController: UIViewController {
    var previewingClip: Clip? { get }
    var previewingCell: ClipCollectionViewCell? { get }
    func displayOnScreenPreviewingCellIfNeeded(shouldAdjust: Bool)
}
