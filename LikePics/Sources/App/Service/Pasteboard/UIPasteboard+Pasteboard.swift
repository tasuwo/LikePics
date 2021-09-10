//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UIPasteboard: Pasteboard {
    func set(_ text: String) {
        string = text
    }

    func get() -> String? {
        return string
    }
}
