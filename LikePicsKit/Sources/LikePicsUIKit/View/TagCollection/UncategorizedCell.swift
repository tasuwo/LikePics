//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol UncategorizedCellDelegate: AnyObject {
    func didTap(_ cell: UncategorizedCell)
}

public class UncategorizedCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "UncategorizedCell", bundle: Bundle.module)
    }

    public weak var delegate: UncategorizedCellDelegate?

    @IBOutlet var button: UIButton!

    @IBAction func didTap(_ sender: Any) {
        self.delegate?.didTap(self)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - Methods

    public func setupAppearance() {
        self.button.setTitle(L10n.uncategorizedCellTitle, for: .normal)
        self.button.titleLabel?.adjustsFontForContentSizeCategory = true
        self.button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }

    public static func preferredSize() -> CGSize {
        let label = UILabel()
        label.text = L10n.uncategorizedCellTitle
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.sizeToFit()

        let width = label.frame.width
        let height = label.frame.height + 16

        return .init(width: width, height: height)
    }
}
