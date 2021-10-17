//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol EmptyMessageViewDelegate: AnyObject {
    func didTapActionButton(_ view: EmptyMessageView)
}

public class EmptyMessageView: UIView {
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

    public var actionButtonTitle: String? {
        get {
            self.actionButton.titleLabel?.text
        }
        set {
            self.actionButton.setTitle(newValue, for: .normal)
        }
    }

    public var isTitleHidden: Bool {
        get {
            self.titleLabel.isHidden
        }
        set {
            self.titleLabel.isHidden = newValue
        }
    }

    public var isMessageHidden: Bool {
        get {
            self.messageLabel.isHidden
        }
        set {
            self.messageLabel.isHidden = newValue
        }
    }

    public var isActionButtonHidden: Bool {
        get {
            self.actionButton.isHidden
        }
        set {
            self.actionButton.isHidden = newValue
        }
    }

    public weak var delegate: EmptyMessageViewDelegate?

    @IBOutlet var baseView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var actionButton: UIButton!

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

    // MARK: - IBActions

    @IBAction func didTapAction(_ sender: Any) {
        self.delegate?.didTapActionButton(self)
    }

    // MARK: - Methods

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.actionButton.layer.borderColor = UIColor.secondaryLabel.cgColor
        }
    }

    private func setupFromNib() {
        Bundle.module.loadNibNamed("EmptyMessageView", owner: self, options: nil)
        self.baseView.frame = self.bounds
        self.addSubview(self.baseView)
        self.sendSubviewToBack(self.baseView)
    }

    private func setupAppearance() {
        self.actionButton.layer.borderWidth = 1
        self.actionButton.layer.cornerRadius = 5
        self.actionButton.layer.cornerCurve = .continuous
        self.actionButton.layer.borderColor = UIColor.secondaryLabel.cgColor
        self.actionButton.contentEdgeInsets = .init(top: 5, left: 7, bottom: 5, right: 7)
    }
}
