//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public class ClipsCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib {
        return UINib(nibName: "ClipsCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public static let secondaryStickingOutMargin: CGFloat = 20
    public static let tertiaryStickingOutMargin: CGFloat = 15

    static let cornerRadius: CGFloat = 10
    static let shadowOpacity: Float = 0.5

    public var primaryImage: UIImage? {
        get {
            self.primaryImageView.image
        }
        set {
            self.primaryImageView.isHidden = (newValue == nil)
            self.primaryImageShadowView.isHidden = (newValue == nil)
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
            self.secondaryImageShadowView.isHidden = (newValue == nil)
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
            self.tertiaryImageShadowView.isHidden = (newValue == nil)
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

    @IBOutlet var primaryImageShadowView: UIView!
    @IBOutlet var secondaryImageShadowView: UIView!
    @IBOutlet var tertiaryImageShadowView: UIView!

    @IBOutlet var secondaryImageOverlayView: UIView!
    @IBOutlet var tertiaryImageOverlayView: UIView!

    @IBOutlet var imagesContainerView: UIView!

    private var imageViews: [UIImageView] {
        return [
            self.primaryImageView,
            self.secondaryImageView,
            self.tertiaryImageView
        ]
    }

    private var imageShadowViews: [UIView] {
        return [
            self.primaryImageShadowView,
            self.secondaryImageShadowView,
            self.tertiaryImageShadowView
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

    static func setupAppearance(imageView: UIImageView) {
        imageView.layer.cornerRadius = Self.cornerRadius
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    static func setupAppearance(shadowView: UIView, onImage: Bool = false) {
        shadowView.layer.cornerRadius = Self.cornerRadius
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = onImage ? 0.3 : Self.shadowOpacity
        shadowView.layer.shadowRadius = 8
        shadowView.layer.shadowOffset = .init(width: 0, height: 8)
        shadowView.clipsToBounds = false
        shadowView.layer.masksToBounds = false
    }

    private func setupAppearance() {
        self.imageViews.forEach {
            $0.isHidden = true
            Self.setupAppearance(imageView: $0)
        }

        self.imageShadowViews.forEach {
            $0.isHidden = true
            Self.setupAppearance(shadowView: $0, onImage: true)
        }

        self.overlayViews.forEach {
            $0.isHidden = true
            $0.layer.cornerRadius = Self.cornerRadius
        }

        self.imagesContainerView.layer.cornerRadius = Self.cornerRadius
        self.imagesContainerView.clipsToBounds = true
        self.imagesContainerView.layer.masksToBounds = true

        Self.setupAppearance(shadowView: self.contentView)

        self.clipsToBounds = false
        self.layer.masksToBounds = false
    }
}
