//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class TagCollectionViewCell: UICollectionViewCell {
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
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.systemGray3.cgColor
    }

    func updateAppearance() {
        self.iconImage.image = self.isSelected ? UIImage(systemName: "checkmark") : UIImage(systemName: "tag.fill")
        self.iconImage.tintColor = self.isSelected ? UIColor.white : UIColor.label
        self.titleLabel.textColor = self.isSelected ? UIColor.white : UIColor.label
        self.contentView.backgroundColor = self.isSelected ? UIColor.systemGreen : UIColor.systemBackground
        self.layer.borderWidth = self.isSelected ? 0 : 2
    }
}
