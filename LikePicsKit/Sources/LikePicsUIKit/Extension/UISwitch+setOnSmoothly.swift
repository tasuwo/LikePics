//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UISwitch {
    public func setOnSmoothly(_ isOn: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setOn(isOn, animated: true)
        }
    }
}
