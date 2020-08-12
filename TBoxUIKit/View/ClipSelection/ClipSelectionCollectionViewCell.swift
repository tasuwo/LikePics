//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Kingfisher
import UIKit

public class ClipSelectionCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipSelectionCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var imageUrl: URL? {
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

    public var image: UIImage? {
        get {
            self.imageView.image
        }
        set {
            self.imageView.image = newValue
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.overlayView.isHidden = !isSelected
            self.checkMarkView.isHidden = !isSelected

            guard self.isSelected != oldValue else { return }
            if isSelected {
                UIView.animate(withDuration: 0.2,
                               delay: 0.0,
                               usingSpringWithDamping: 0.8,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                   self.transform = self.transform.scaledBy(x: 0.85, y: 0.85)
                               },
                               completion: nil)
            } else {
                UIView.animate(withDuration: 0.2,
                               delay: 0.0,
                               usingSpringWithDamping: 0.4,
                               initialSpringVelocity: 1.0,
                               options: .curveEaseOut,
                               animations: {
                                   self.transform = CGAffineTransform.identity.scaledBy(x: 1.0, y: 1.0)
                               },
                               completion: nil)
            }
        }
    }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var checkMarkView: UIImageView!
    @IBOutlet var overlayView: UIView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.layer.cornerRadius = 10
        self.overlayView.isHidden = true
        self.checkMarkView.isHidden = true
    }

    private func apply(imageUrl: URL) {
        var options: KingfisherOptionsInfo = []

        if let provider = WebImageProviderPreset.resolveProvider(by: imageUrl),
            provider.shouldModifyRequest(for: imageUrl)
        {
            let modifier = AnyModifier(modify: provider.modifyRequest)
            options.append(.requestModifier(modifier))
        }

        let processor = RoundCornerImageProcessor(cornerRadius: 10)
        options.append(.processor(processor))

        self.imageView.kf.setImage(with: imageUrl, placeholder: nil, options: options)
    }
}
