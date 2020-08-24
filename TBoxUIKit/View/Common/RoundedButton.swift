//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class RoundedButton: UIButton {
    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.backgroundColor = UIColor.systemBlue
        self.contentEdgeInsets = .init(top: 10, left: 12, bottom: 10, right: 12)
        self.layer.cornerRadius = 18

        self.titleLabel?.font = .systemFont(ofSize: 14, weight: .heavy)
    }
}
