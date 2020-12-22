//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public class ClipSelectionCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipSelectionCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var id: UUID?
    public var image: UIImage? {
        didSet {
            guard let image = self.image else {
                self.imageView.image = nil
                return
            }
            UIView.transition(with: self.imageView,
                              duration: 0.2,
                              options: .transitionCrossDissolve,
                              animations: { self.imageView.image = image },
                              completion: nil)
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

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    private func setupAppearance() {
        self.layer.cornerRadius = 10
        self.overlayView.isHidden = true
        self.selectionOrderLabel.isHidden = true
    }

    private func updateSelectionOrderAppearance() {
        self.selectionOrderLabel.isHidden = !self.isSelected && self.selectionOrder != nil
    }
}
