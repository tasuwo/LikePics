//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol AlbumListCollectionViewCellDelegate: AnyObject {
    func didTapDeleteButton(_ cell: AlbumListCollectionViewCell)
}

public class AlbumListCollectionViewCell: UICollectionViewCell {
    public static let preferredWidth: CGFloat = 180
    public static let preferredHeight: CGFloat = 230

    public static var nib: UINib {
        return UINib(nibName: "AlbumListCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var thumbnail: UIImage? {
        get {
            self.thumbnailImageView.image
        }
        set {
            self.thumbnailImageView.image = newValue
        }
    }

    public var title: String? {
        get {
            self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var visibleDeleteButton: Bool {
        get {
            return !self.deleteButton.isHidden
        }
        set {
            self.deleteButton.isHidden = !newValue
        }
    }

    public weak var deletate: AlbumListCollectionViewCellDelegate?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    @IBAction func didTapDeleteButton(_ sender: Any) {
        self.deletate?.didTapDeleteButton(self)
    }

    // MARK: - Methods

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFit
        self.visibleDeleteButton = false
    }
}
