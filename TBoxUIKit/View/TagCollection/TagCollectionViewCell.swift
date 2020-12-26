//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol TagCollectionViewCellDelegate: AnyObject {
    func didTapDeleteButton(_ cell: TagCollectionViewCell)
}

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
            self.updateForDisplayMode()
        }
    }

    public var visibleDeleteButton: Bool {
        get {
            return !self.deleteButtonContainer.isHidden
        }
        set {
            self.deleteButtonContainer.isHidden = !newValue
        }
    }

    public var visibleCountIfPossible: Bool = true {
        didSet {
            self.updateLabel()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.updateForDisplayMode()
        }
    }

    @IBOutlet var iconImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var deleteButtonContainer: UIView!

    public weak var delegate: TagCollectionViewCellDelegate?

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

    @IBAction func tapDeleteButton(_ sender: UIButton) {
        self.delegate?.didTapDeleteButton(self)
    }

    func setupAppearance() {
        self.layer.cornerCurve = .continuous

        self.visibleDeleteButton = false

        self.updateRadius()
        self.updateColors()
        self.updateForDisplayMode()
    }

    func updateRadius() {
        self.layer.cornerRadius = self.bounds.size.height / 4
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
            self.layer.borderWidth = 1

        default:
            self.iconImage.image = UIImage(systemName: "tag.fill")
            self.iconImage.tintColor = UIColor.label
            self.titleLabel.textColor = UIColor.label
            self.contentView.backgroundColor = UIColor.systemBackground
            self.layer.borderWidth = 1
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
}
