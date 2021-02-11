//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UISearchController {
    func set(isEnabled: Bool) {
        guard searchBar.isUserInteractionEnabled != isEnabled else { return }

        resignFirstResponder()

        searchBar.isUserInteractionEnabled = isEnabled
        searchBar.alpha = isEnabled ? 1.0 : 0.3
        if !isEnabled, isActive {
            isActive = false
        }
    }

    func set(text: String) {
        guard searchBar.text != text else { return }

        searchBar.text = text

        if text.isEmpty {
            searchBar.resignFirstResponder()
        }
    }
}
