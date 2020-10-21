//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class AlbumSelectionCell: UITableViewCell {
    public static var nib: UINib {
        return UINib(nibName: "AlbumSelectionCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: Album.Identity?

    public var title: String? {
        get {
            return self.titleLabel.text
        }
        set {
            self.titleLabel.text = newValue
        }
    }

    public var thumbnail: UIImage? {
        get {
            self.thumbnailImageView.image
        }
        set {
            self.thumbnailImageView.image = newValue
        }
    }

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()

        self.setupAppearance()
    }

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.layer.cornerCurve = .continuous
        self.thumbnailImageView.contentMode = .scaleAspectFill
        self.thumbnailImageView.clipsToBounds = true
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
    }
}
