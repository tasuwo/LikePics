//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

class ClipTargetCollectionViewHeader: UICollectionReusableView {
    static var nib: UINib {
        return UINib(nibName: "ClipTargetCollectionViewHeader", bundle: Bundle.main)
    }

    static let preferredHeight: CGFloat = 50

    var selectionCount: Int = 0 {
        didSet {
            self.titleLabel.text = "\(self.selectionCount) 件を選択"
        }
    }

    @IBOutlet var titleLabel: UILabel!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.selectionCount = 0
    }
}
