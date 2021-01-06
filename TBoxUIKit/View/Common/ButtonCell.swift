//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ButtonCellDelegate: AnyObject {
    func didTap(_ cell: ButtonCell)
}

public class ButtonCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ButtonCell", bundle: Bundle(for: Self.self))
    }

    public var title: String? {
        didSet {
            self.additionButton.setTitle(self.title, for: .normal)
        }
    }

    @IBOutlet var additionButton: UIButton!

    public weak var delegate: ButtonCellDelegate?

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    // MARK: - Methods

    public func setupAppearance() {
        self.additionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.additionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
    }

    @IBAction func tapAdditionButton(_ sender: UIButton) {
        self.delegate?.didTap(self)
    }
}
