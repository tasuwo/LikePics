//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UIImageView {
    func addAspectRatioConstraint(image: UIImage?) {
        if let image = image {
            removeAspectRatioConstraint()
            let aspectRatio = image.size.width / image.size.height
            let constraint = NSLayoutConstraint(item: self,
                                                attribute: .width,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .height,
                                                multiplier: aspectRatio,
                                                constant: 0.0)
            addConstraint(constraint)
        }
    }

    func removeAspectRatioConstraint() {
        for constraint in self.constraints where (constraint.firstItem as? UIImageView) == self && (constraint.secondItem as? UIImageView) == self {
            removeConstraint(constraint)
        }
    }
}
