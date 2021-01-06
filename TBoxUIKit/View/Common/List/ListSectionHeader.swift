//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ListSectionHeaderDelegate: AnyObject {
    func didTapAdd(_ header: ListSectionHeader)
}

public class ListSectionHeader: UICollectionReusableView {
    public static var nib: UINib {
        return UINib(nibName: "ListSectionHeader", bundle: Bundle(for: Self.self))
    }

    public var identifier: String?

    public var title: String? {
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

    public weak var delegate: ListSectionHeaderDelegate?

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
        self.visibleAddButton = false
    }
}
