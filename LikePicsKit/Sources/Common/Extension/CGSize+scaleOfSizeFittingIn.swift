//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

extension CGSize {
    public func scale(fittingIn target: CGSize) -> CGFloat {
        let widthScale = target.width / width
        let heightScale = target.height / height
        return min(widthScale, heightScale)
    }
}
