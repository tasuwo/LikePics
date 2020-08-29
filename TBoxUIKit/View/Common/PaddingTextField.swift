//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

@IBDesignable open class PaddingTextField: UITextField {
    @IBInspectable open var padding: UIEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: 0)

    // MARK: - UITextField (Override)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.padding)
    }
}
