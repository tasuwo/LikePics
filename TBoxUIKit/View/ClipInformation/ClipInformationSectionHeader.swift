//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationSectionHeaderDelegate: AnyObject {
    func didTapAdd(_ header: ClipInformationSectionHeader)
}

public class ClipInformationSectionHeader: UICollectionReusableView {
    static var nib: UINib {
        return UINib(nibName: "ClipInformationSectionHeader", bundle: Bundle(for: Self.self))
    }

    var identifier: String?

    var title: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var visibleAddButton: Bool {
        get {
            !self.addButtonContainer.isHidden
        }
        set {
            self.addButtonContainer.isHidden = !newValue
        }
    }

    weak var delegate: ClipInformationSectionHeaderDelegate?

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var addButtonContainer: UIView!

    // MARK: - IBAction

    @IBAction func didTapAdd(_ sender: UIButton) {
        self.delegate?.didTapAdd(self)
    }

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    private func setupAppearance() {
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)

        self.visibleAddButton = false
    }
}
