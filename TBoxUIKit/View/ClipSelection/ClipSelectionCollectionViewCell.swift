//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class ClipSelectionCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipSelectionCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public var identifier: String?
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
        }
    }

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var selectionOrderLabel: UILabel!
    @IBOutlet var selectionOrderLabelContainer: UIView!

    // MARK: - Methods

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    private func setupAppearance() {
        self.layer.cornerRadius = 10
        self.selectionOrderLabelContainer.layer.borderWidth = 2.25
        self.selectionOrderLabelContainer.layer.borderColor = UIColor.white.cgColor
        self.overlayView.isHidden = true
        self.selectionOrderLabel.isHidden = true
    }

    private func updateSelectionOrderAppearance() {
        self.selectionOrderLabel.isHidden = !self.isSelected && self.selectionOrder != nil
    }
}

extension ClipSelectionCollectionViewCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.image = nil
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.image = image
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            self.image = nil
        }
    }
}

extension ClipSelectionCollectionViewCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        if let originalSize = originalPixelSize {
            if originalSize.width < originalSize.height {
                return .init(width: frame.width,
                             height: frame.width * (originalSize.height / originalSize.width))
            } else {
                return .init(width: frame.height * (originalSize.width / originalSize.height),
                             height: frame.height)
            }
        } else {
            return frame.size
        }
    }
}
