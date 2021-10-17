//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

class PreviewImageView: UIImageView {
    var originalSize: CGSize? {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        guard let originalSize = originalSize else {
            return super.intrinsicContentSize
        }
        return originalSize
    }
}
