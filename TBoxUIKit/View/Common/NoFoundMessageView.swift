//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class NotFoundMessageView: UIView {
    public var title: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var message: String? {
        get {
            self.messageLabel.text
        }
        set {
            self.messageLabel.text = newValue
        }
    }

    @IBOutlet var baseView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!

    // MARK: - Lifecycle

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.setupFromNib()
        self.setupAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        self.setupFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupFromNib() {
        Bundle(for: type(of: self)).loadNibNamed("NotFoundMessageView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        let metrics = UIFontMetrics(forTextStyle: .title2)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title2)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .bold)
        titleLabel.font = metrics.scaledFont(for: font)
    }
}
