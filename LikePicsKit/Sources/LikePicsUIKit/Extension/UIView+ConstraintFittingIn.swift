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

    func constraints(fittingIn guide: UILayoutGuide) -> [NSLayoutConstraint] {
        return [
            self.topAnchor.constraint(equalTo: guide.topAnchor),
            self.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            self.leftAnchor.constraint(equalTo: guide.leftAnchor),
            self.rightAnchor.constraint(equalTo: guide.rightAnchor)
        ]
    }
}
