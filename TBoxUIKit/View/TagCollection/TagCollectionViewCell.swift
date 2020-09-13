//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class TagCollectionViewCell: UICollectionViewCell {
    public enum DisplayMode {
        case normal
        case checkAtSelect
    }

    public static let preferredHeight: CGFloat = 24 + 4 * 2

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
            self.updateAppearance()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.updateAppearance()
        }
    }

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.layer.borderColor = UIColor.systemGray3.cgColor
        }
    }

    // MARK: - Methods

    public static func preferredSize(for text: String) -> CGSize {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14)
        label.sizeToFit()
        return CGSize(width: label.frame.width + 8 + 16 + 4 + 8,
                      height: Self.preferredHeight)
    }

    func setupAppearance() {
        self.layer.cornerRadius = Self.preferredHeight / 2
        self.layer.borderColor = UIColor.systemGray3.cgColor
        self.updateAppearance()
    }

    func updateAppearance() {
        if self.isSelected, self.displayMode == .checkAtSelect {
            self.iconImage.image = UIImage(systemName: "checkmark")
            self.iconImage.tintColor = UIColor.white
            self.titleLabel.textColor = UIColor.white
            self.contentView.backgroundColor = UIColor.systemGreen
            self.layer.borderWidth = 0
        } else {
            self.iconImage.image = UIImage(systemName: "tag.fill")
            self.iconImage.tintColor = UIColor.label
            self.titleLabel.textColor = UIColor.label
            self.contentView.backgroundColor = UIColor.systemBackground
            self.layer.borderWidth = 2
        }
    }
}
