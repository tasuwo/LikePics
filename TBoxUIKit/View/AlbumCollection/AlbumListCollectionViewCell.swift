//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

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

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFit
    }
}
