//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

#if canImport(UIKit)

import UIKit

public extension UIView {
    static func likepics_animate(withDuration duration: TimeInterval,
                                 bounce: CGFloat = 0,
                                 delay: TimeInterval = 0,
                                 options: AnimationOptions = [],
                                 animations: @escaping () -> Void,
                                 completion: ((Bool) -> Void)? = nil)
    {
        if #available(iOS 17.0, *) {
            var options = options
            options.remove(.curveEaseIn)
            options.remove(.curveEaseOut)
            options.remove(.curveEaseInOut)
            UIView.animate(springDuration: duration, bounce: bounce, delay: delay, options: options, animations: animations, completion: completion)
        } else {
            UIView.animate(withDuration: duration, delay: delay, options: options, animations: animations, completion: completion)
        }
    }
}

#endif
