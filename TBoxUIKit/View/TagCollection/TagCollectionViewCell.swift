//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class TagCollectionViewCell: UICollectionViewCell {
    public enum DisplayMode {
        case normal
        case checkAtSelect
        case deletion
    }

    public static var nib: UINib {
        return UINib(nibName: "TagCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var title: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var displayMode: DisplayMode = .checkAtSelect {
        didSet {
            self.updateForDisplayMode()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.updateForDisplayMode()
        }
    }

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.updateRadius()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.layer.borderColor = UIColor.systemGray3.cgColor
        }
    }

    func setupAppearance() {
        self.layer.cornerCurve = .continuous

        self.updateRadius()
        self.updateColors()
        self.updateForDisplayMode()
    }

    func updateRadius() {
        self.layer.cornerRadius = self.bounds.size.height / 2
    }

    func updateColors() {
        self.layer.borderColor = UIColor.systemGray3.cgColor
    }

    func updateForDisplayMode() {
        switch (self.displayMode, self.isSelected) {
        case (.checkAtSelect, true):
            self.iconImage.image = UIImage(systemName: "checkmark")
            self.iconImage.tintColor = UIColor.white
            self.titleLabel.textColor = UIColor.white
            self.contentView.backgroundColor = UIColor.systemGreen
            self.layer.borderWidth = 0

        case (.deletion, true):
            self.iconImage.image = UIImage(systemName: "checkmark")
            self.iconImage.tintColor = UIColor.white
            self.titleLabel.textColor = UIColor.white
            self.contentView.backgroundColor = UIColor.systemRed
            self.layer.borderWidth = 0

        case (.deletion, false):
            self.iconImage.image = UIImage(systemName: "minus.circle.fill")
            self.iconImage.tintColor = .systemRed
            self.titleLabel.textColor = UIColor.label
            self.contentView.backgroundColor = UIColor.systemBackground
            self.layer.borderWidth = 2

        default:
            self.iconImage.image = UIImage(systemName: "tag.fill")
            self.iconImage.tintColor = UIColor.label
            self.titleLabel.textColor = UIColor.label
            self.contentView.backgroundColor = UIColor.systemBackground
            self.layer.borderWidth = 2
        }
    }
}
