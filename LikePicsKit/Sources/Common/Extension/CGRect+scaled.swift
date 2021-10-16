//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public extension CGRect {
    func scaled(_ scale: CGFloat) -> CGRect {
        self.inset(by: .init(top: (height - height * scale) / 2,
                             left: (width - width * scale) / 2,
                             bottom: (height - height * scale) / 2,
                             right: (width - width * scale) / 2))
    }
}
