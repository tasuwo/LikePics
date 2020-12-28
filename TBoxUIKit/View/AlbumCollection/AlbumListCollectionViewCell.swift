//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

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

    public var clipCount: Int? {
        didSet {
            if let count = self.clipCount {
                self.metaLabel.text = L10n.albumListCollectionViewCellCount(count)
                self.metaLabel.isHidden = false
            } else {
                self.metaLabel.text = nil
                self.metaLabel.isHidden = true
            }
        }
    }

    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var metaLabel: UILabel!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    func setupAppearance() {
        self.thumbnailImageView.layer.cornerRadius = 10
        self.thumbnailImageView.contentMode = .scaleAspectFill
        self.clipCount = nil
    }
}
