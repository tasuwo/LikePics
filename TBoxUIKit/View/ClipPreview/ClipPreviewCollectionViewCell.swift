//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipPreviewCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipPreviewCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var image: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue
            self.imageView.addAspectRatioConstraint(image: image)
        }
    }

    @IBOutlet var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
    }
}
