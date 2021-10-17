//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class MultiLineButton: UIButton {
    override var bounds: CGRect {
        didSet {
            if !oldValue.equalTo(bounds) {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        guard let titleLabel = titleLabel else { return .zero }
        let labelSize = titleLabel.sizeThatFits(CGSize(width: frame.width - (titleEdgeInsets.left + titleEdgeInsets.right),
                                                       height: .greatestFiniteMagnitude))
        let desiredButtonSize = CGSize(width: labelSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                                       height: labelSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
        return desiredButtonSize
    }

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.titleLabel?.numberOfLines = 2
        self.titleLabel?.lineBreakMode = .byTruncatingTail
    }
}
