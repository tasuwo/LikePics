//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class ClipSelectionCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipSelectionCollectionViewCell", bundle: Bundle.module)
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

    public var displaySelectionOrder = true {
        didSet {
            self.updateSelectionOrderAppearance()
        }
    }

    override public var isSelected: Bool {
        didSet {
            self.overlayView.isHidden = !isSelected
            self.updateSelectionOrderAppearance()
        }
    }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var selectionOrderLabel: UILabel!
    @IBOutlet var selectionOrderLabelContainer: UIView!
    @IBOutlet var selectionMarkContainer: UIView!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            self.setupAppearance()
        }
    }

    override public func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    private func setupAppearance() {
        layer.cornerRadius = 10
        selectionOrderLabelContainer.layer.borderWidth = 2.25
        selectionOrderLabelContainer.layer.borderColor = UIColor.white.cgColor
        selectionMarkContainer.backgroundColor = .white
        selectionMarkContainer.layer.cornerRadius = selectionMarkContainer.bounds.width / 2.0
        overlayView.isHidden = true
        selectionOrderLabel.isHidden = true
    }

    private func updateSelectionOrderAppearance() {
        if displaySelectionOrder {
            selectionOrderLabel.isHidden = !self.isSelected && self.selectionOrder != nil

            selectionMarkContainer.isHidden = true
            selectionOrderLabelContainer.isHidden = !self.isSelected
        } else {
            selectionMarkContainer.isHidden = !self.isSelected
            selectionOrderLabelContainer.isHidden = true
        }
    }
}

extension ClipSelectionCollectionViewCell: ImageDisplayable {
    // MARK: - ImageDisplayable

    public func smt_display(_ image: UIImage?) {
        guard let image = image else {
            self.backgroundColor = Asset.Color.secondaryBackground.color
            self.imageView.image = nil
            return
        }

        UIView.transition(
            with: self.imageView,
            duration: 0.2,
            options: .transitionCrossDissolve,
            animations: { self.imageView.image = image },
            completion: nil
        )
    }
}

extension ClipSelectionCollectionViewCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        if let originalSize = originalPixelSize {
            if originalSize.width < originalSize.height {
                return .init(
                    width: frame.width,
                    height: frame.width * (originalSize.height / originalSize.width)
                )
            } else {
                return .init(
                    width: frame.height * (originalSize.width / originalSize.height),
                    height: frame.height
                )
            }
        } else {
            return frame.size
        }
    }
}
