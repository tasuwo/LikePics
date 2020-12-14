//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UIView {
    func constraints(fittingIn view: UIView) -> [NSLayoutConstraint] {
        return [
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.leftAnchor.constraint(equalTo: view.leftAnchor),
            self.rightAnchor.constraint(equalTo: view.rightAnchor)
        ]
    }
}
