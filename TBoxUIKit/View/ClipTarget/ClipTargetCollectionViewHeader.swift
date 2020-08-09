//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipTargetCollectionViewHeader: UICollectionReusableView {
    public static var nib: UINib {
        return UINib(nibName: "ClipTargetCollectionViewHeader", bundle: Bundle(for: Self.self))
    }

    public static let preferredHeight: CGFloat = 50

    public var selectionCount: Int = 0 {
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
