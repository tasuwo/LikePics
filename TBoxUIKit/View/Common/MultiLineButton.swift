//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class MultiLineButton: UIButton {
    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setupAppearance()
    }

    private func setupAppearance() {
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.lineBreakMode = .byWordWrapping
    }

    // MARK: - Overrides (UIButton)

    override var intrinsicContentSize: CGSize {
        return titleLabel?.intrinsicContentSize ?? CGSize.zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.preferredMaxLayoutWidth = titleLabel?.frame.size.width ?? 0
        super.layoutSubviews()
    }
}
