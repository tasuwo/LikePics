//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipItemListPresentingCell: UICollectionViewCell {
    func thumbnail() -> UIImageView
    func calcImageFrame(size: CGSize) -> CGRect
}
