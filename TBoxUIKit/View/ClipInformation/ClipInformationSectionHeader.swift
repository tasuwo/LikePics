//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipInformationSectionHeader: UICollectionReusableView {
    static var nib: UINib {
        return UINib(nibName: "ClipInformationSectionHeader", bundle: Bundle(for: Self.self))
    }

    var title: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    @IBOutlet var titleLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    }
}
