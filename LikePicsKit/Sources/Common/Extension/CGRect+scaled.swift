//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)

import CoreGraphics
import UIKit

extension CGRect {
    public func scaled(_ scale: CGFloat) -> CGRect {
        self.inset(
            by: UIEdgeInsets(
                top: (height - height * scale) / 2,
                left: (width - width * scale) / 2,
                bottom: (height - height * scale) / 2,
                right: (width - width * scale) / 2
            )
        )
    }
}

#endif
