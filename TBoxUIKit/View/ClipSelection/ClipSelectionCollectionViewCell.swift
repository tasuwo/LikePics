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
            self.imageView.kf.cancelDownloadTask()
        }
        didSet {
            guard let url = self.imageUrl else {
                self.imageView.image = nil
                return
            }
            self.apply(imageUrl: url)
        }
    }

    public var selectionOrder: Int? {
        didSet {
            if let order = selectionOrder {
                self.selectionOrderLabel.text = String(order)
            } else {
                self.selectionOrderLabel.text = nil
            }
            self.updateSelectionOrderAppearance()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.overlayView.isHidden = !isSelected
            self.updateSelectionOrderAppearance()

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
    @IBOutlet var overlayView: UIView!
    @IBOutlet var selectionOrderLabel: UILabel!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.layer.cornerRadius = 10
        self.overlayView.isHidden = true
        self.selectionOrderLabel.isHidden = true
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

    private func updateSelectionOrderAppearance() {
        self.selectionOrderLabel.isHidden = !self.isSelected && self.selectionOrder != nil
    }
}
