//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class MultilineUIButton: UIButton {
    override public var intrinsicContentSize: CGSize {
        return self.titleLabel?.intrinsicContentSize ?? .zero
    }

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupAppearance()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.titleLabel?.preferredMaxLayoutWidth = self.titleLabel?.frame.size.width ?? .zero
        super.layoutSubviews()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.titleLabel?.numberOfLines = 0
        self.titleLabel?.lineBreakMode = .byCharWrapping
    }
}
