//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipInformationCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipInformationCell", bundle: Bundle(for: Self.self))
    }

    public var visibleBottomAccessoryView: Bool {
        get {
            return !self.bottomAccessoryView.isHidden
        }
        set {
            self.bottomAccessoryView.isHidden = !newValue
        }
    }

    public var visibleRightAccessoryView: Bool {
        get {
            return !self.rightAccessoryLabel.isHidden
        }
        set {
            self.rightAccessoryLabel.isHidden = !newValue
        }
    }

    public var visibleSeparator: Bool {
        get {
            return !self.separator.isHidden
        }
        set {
            self.separator.isHidden = !newValue
        }
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var rightAccessoryLabel: UILabel!
    @IBOutlet var bottomAccessoryButton: UIButton!
    @IBOutlet var bottomAccessoryView: UIView!
    @IBOutlet var separator: UIView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.separator.backgroundColor = .separator

        [
            self.titleLabel,
            self.rightAccessoryLabel,
            self.bottomAccessoryButton.titleLabel
        ].forEach {
            $0?.adjustsFontForContentSizeCategory = true
            $0?.font = UIFont.preferredFont(forTextStyle: .body)
        }

        self.visibleRightAccessoryView = false
        self.visibleBottomAccessoryView = false
    }
}
