//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol AlbumListCollectionViewCellDelegate: AnyObject {
    func didTapDeleteButton(_ cell: AlbumListCollectionViewCell)
}

public class AlbumListCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumListCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: Album.Identity?

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

    public var deleteButtonPlacement: UIView {
        return self.deleteButton
    }

    public weak var delegate: AlbumListCollectionViewCellDelegate?

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var deleteButton: UIButton!

    // MARK: - IBActions

    @IBAction func didTapDeleteButton(_ sender: Any) {
        self.delegate?.didTapDeleteButton(self)
    }

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFit
        self.visibleDeleteButton = false
    }
}
