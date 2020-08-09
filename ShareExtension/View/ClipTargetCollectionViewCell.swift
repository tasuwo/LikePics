//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Kingfisher
import UIKit

class ClipTargetCollectionViewCell: UICollectionViewCell {
    static var nib: UINib {
        return UINib(nibName: "ClipTargetCollectionViewCell", bundle: Bundle.main)
    }

    var imageUrl: URL? {
        willSet {
            // TODO: Cancel loading image
        }
        didSet {
            guard let url = self.imageUrl else {
                self.imageView.image = nil
                return
            }
            self.apply(imageUrl: url)
        }
    }

    @IBOutlet var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.layer.cornerRadius = 10
    }

    private func apply(imageUrl: URL) {
        var options: KingfisherOptionsInfo = []

        if let provider = WebImageProviderPreset.resolveProvider(by: imageUrl),
            provider.shouldModifyRequest
        {
            let modifier = AnyModifier(modify: provider.modifyRequest)
            options.append(.requestModifier(modifier))
        }

        let processor = RoundCornerImageProcessor(cornerRadius: 10)
        options.append(.processor(processor))

        self.imageView.kf.setImage(with: imageUrl, placeholder: nil, options: options)
    }
}
