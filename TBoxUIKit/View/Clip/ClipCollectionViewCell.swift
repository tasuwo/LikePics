//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public static let secondaryStickingOutMargin: CGFloat = 20
    public static let tertiaryStickingOutMargin: CGFloat = 15

    public var primaryImage: UIImage? {
        get {
            self.primaryImageView.image
        }
        set {
            self.primaryImageView.isHidden = (newValue == nil)
            self.primaryImageView.removeAspectRatioConstraint()

            if let image = newValue {
                self.primaryImageView.addAspectRatioConstraint(image: image)
            }

            self.primaryImageView.image = newValue
        }
    }

    public var secondaryImage: UIImage? {
        get {
            self.secondaryImageView.image
        }
        set {
            self.secondaryImageView.isHidden = (newValue == nil)
            self.secondaryImageOverlayView.isHidden = (newValue == nil)

            self.secondaryImageView.removeAspectRatioConstraint()
            if let image = newValue {
                self.secondaryImageView.addAspectRatioConstraint(image: image)
            }

            self.secondaryImageView.image = newValue
        }
    }

    public var tertiaryImage: UIImage? {
        get {
            self.tertiaryImageView.image
        }
        set {
            self.tertiaryImageView.isHidden = (newValue == nil)
            self.tertiaryImageOverlayView.isHidden = (newValue == nil)

            self.tertiaryImageView.removeAspectRatioConstraint()
            if let image = newValue {
                self.tertiaryImageView.addAspectRatioConstraint(image: image)
            }

            self.tertiaryImageView.image = newValue
        }
    }

    @IBOutlet var primaryImageView: UIImageView!
    @IBOutlet var secondaryImageView: UIImageView!
    @IBOutlet var tertiaryImageView: UIImageView!

    @IBOutlet var secondaryImageOverlayView: UIView!
    @IBOutlet var tertiaryImageOverlayView: UIView!

    private var imageViews: [UIImageView] {
        return [
            self.primaryImageView,
            self.secondaryImageView,
            self.tertiaryImageView
        ]
    }

    private var overlayViews: [UIView] {
        return [
            self.secondaryImageOverlayView,
            self.tertiaryImageOverlayView
        ]
    }

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.layer.cornerRadius = 10
        self.imageViews.forEach { $0.layer.cornerRadius = 10 }
        self.overlayViews.forEach { $0.layer.cornerRadius = 10 }

        self.imageViews.forEach { $0.isHidden = true }
        self.overlayViews.forEach { $0.isHidden = true }

        self.imageViews.forEach {
            $0.layer.borderWidth = 2
            $0.layer.borderColor = UIColor.lightGray.cgColor
        }

        self.clipsToBounds = true
    }
}

private extension UIImageView {
    func addAspectRatioConstraint(image: UIImage?) {
        if let image = image {
            removeAspectRatioConstraint()
            let aspectRatio = image.size.width / image.size.height
            let constraint = NSLayoutConstraint(item: self,
                                                attribute: .width,
                                                relatedBy: .equal,
                                                toItem: self,
                                                attribute: .height,
                                                multiplier: aspectRatio,
                                                constant: 0.0)
            addConstraint(constraint)
        }
    }

    func removeAspectRatioConstraint() {
        for constraint in self.constraints {
            if (constraint.firstItem as? UIImageView) == self,
                (constraint.secondItem as? UIImageView) == self
            {
                removeConstraint(constraint)
            }
        }
    }
}
