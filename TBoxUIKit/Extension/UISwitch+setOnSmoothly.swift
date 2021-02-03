//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UISwitch {
    func setOnSmoothly(_ isOn: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setOn(isOn, animated: true)
        }
    }
}
