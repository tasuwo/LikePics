//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

@MainActor
public protocol TagCollectionViewCellDelegate: AnyObject {
    func didTapDeleteButton(_ cell: TagCollectionViewCell)
}

public class TagCollectionViewCell: UICollectionViewCell {
    public enum DisplayMode {
        case normal
        case checkAtSelect
    }

    public static var nib: UINib {
        return UINib(nibName: "TagCollectionViewCell", bundle: Bundle.module)
    }

    public var title: String? {
        didSet {
            self.updateLabel()
        }
    }

    public var count: Int? {
        didSet {
            self.updateLabel()
        }
    }

    public var displayMode: DisplayMode = .checkAtSelect {
        didSet {
            self.updateAppearance()
        }
    }

    public var visibleDeleteButton: Bool {
        get {
            return !self.deleteButtonContainer.isHidden
        }
        set {
            self.deleteButtonContainer.isHidden = !newValue
            self.labelMaxWidthConstraint.constant =
                newValue
                ? 220 - self.deleteButtonWidthConstraint.constant
                : 220
        }
    }

    public var visibleCountIfPossible = true {
        didSet {
            self.updateLabel()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.updateAppearance()
        }
    }

    public var isHiddenTag = false {
        didSet {
            self.updateAppearance()
        }
    }

    @IBOutlet var hashTagLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!

    @IBOutlet var checkMarkIcon: UIImageView!
    @IBOutlet var hiddenIcon: UIImageView!

    @IBOutlet var checkMarkContainer: UIView!
    @IBOutlet var hiddenIconContainer: UIView!
    @IBOutlet var deleteButtonContainer: UIView!
    @IBOutlet var hashTagContainer: UIView!

    @IBOutlet var separatorView: UIView!

    @IBOutlet var labelMaxWidthConstraint: NSLayoutConstraint!
    @IBOutlet var deleteButtonWidthConstraint: NSLayoutConstraint!

    public weak var delegate: TagCollectionViewCellDelegate?

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        MainActor.assumeIsolated {
            self.setupAppearance()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.updateRadius()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    @IBAction func tapDeleteButton(_ sender: UIButton) {
        self.delegate?.didTapDeleteButton(self)
    }

    func setupAppearance() {
        self.layer.cornerCurve = .continuous

        self.visibleDeleteButton = false

        self.checkMarkIcon.tintColor = .white
        self.hiddenIcon.tintColor = UIColor.label.withAlphaComponent(0.8)

        separatorView.backgroundColor = UIColor.systemGray3

        self.updateRadius()
        self.updateColors()
        self.updateAppearance()
    }

    func updateRadius() {
        self.layer.cornerRadius = self.bounds.size.height / 2
    }

    func updateColors() {
        self.layer.borderColor = Asset.Color.tagSeparator.color.cgColor
    }

    public func updateAppearance() {
        switch (self.displayMode, self.isSelected) {
        case (.checkAtSelect, true):
            self.contentView.backgroundColor = UIColor.systemGreen
            self.layer.borderWidth = 0

            self.hiddenIconContainer.isHidden = true
            self.checkMarkContainer.isHidden = false
            self.hashTagContainer.isHidden = true

            self.titleLabel.textColor =
                isHiddenTag
                ? UIColor.white.withAlphaComponent(0.8)
                : .white

        default:
            self.contentView.backgroundColor = Asset.Color.secondaryBackground.color
            self.layer.borderWidth = 0.8

            self.hiddenIconContainer.isHidden = isHiddenTag ? false : true
            self.checkMarkContainer.isHidden = true
            self.hashTagContainer.isHidden = isHiddenTag ? true : false

            self.hashTagLabel.textColor =
                isHiddenTag
                ? UIColor.label.withAlphaComponent(0.8)
                : .label
            self.titleLabel.textColor =
                isHiddenTag
                ? UIColor.label.withAlphaComponent(0.8)
                : .label
        }

        self.updateLabel()
    }

    func updateLabel() {
        guard let title = self.title else {
            self.titleLabel.text = nil
            return
        }
        if let count = self.count, self.visibleCountIfPossible {
            self.titleLabel.text = "\(title) (\(count))"
        } else {
            self.titleLabel.text = title
        }
    }

    public static func preferredSize(
        title: String,
        clipCount: Int?,
        isHidden: Bool,
        visibleCountIfPossible: Bool,
        visibleDeleteButton: Bool
    ) -> CGSize {
        let label = UILabel()
        if let count = clipCount, visibleCountIfPossible {
            label.text = "\(title) (\(count))"
        } else {
            label.text = title
        }
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.sizeToFit()

        var width = label.frame.width + 18 + 24
        if visibleDeleteButton {
            width += 44 + 1
        }

        let height = label.frame.height + 16

        return .init(width: min(240, width), height: height)
    }
}
