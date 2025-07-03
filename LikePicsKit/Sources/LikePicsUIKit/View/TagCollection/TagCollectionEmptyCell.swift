//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class TagCollectionEmptyCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "TagCollectionEmptyCell", bundle: Bundle.module)
    }

    public var message: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    @IBOutlet var titleLabel: UILabel!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        MainActor.assumeIsolated {
            self.setupAppearance()
        }
    }

    // MARK: - Methods

    public func setupAppearance() {
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        self.titleLabel.textColor = .lightGray
    }
}
