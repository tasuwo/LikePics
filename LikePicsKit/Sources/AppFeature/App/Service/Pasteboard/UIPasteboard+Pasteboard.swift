//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

extension UIPasteboard: Pasteboard {
    public func set(_ text: String) {
        string = text
    }

    public func get() -> String? {
        return string
    }
}
