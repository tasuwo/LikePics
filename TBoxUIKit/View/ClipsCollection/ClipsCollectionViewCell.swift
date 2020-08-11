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
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
    }

    static func resetAppearance(imageView: UIImageView) {
        imageView.layer.cornerRadius = 0
    }

    private func setupAppearance() {
        self.imageViews.forEach {
            $0.isHidden = true
            Self.setupAppearance(imageView: $0)
        }

        self.imageShadowViews.forEach {
            $0.isHidden = true
            $0.layer.cornerRadius = 10
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.3
            $0.layer.shadowRadius = 8
            $0.layer.shadowOffset = .init(width: 0, height: 8)
            $0.clipsToBounds = false
        }

        self.overlayViews.forEach {
            $0.isHidden = true
            $0.layer.cornerRadius = 10
        }

        self.imagesContainerView.layer.cornerRadius = 10
        self.imagesContainerView.clipsToBounds = true
        self.imagesContainerView.layer.masksToBounds = true

        self.contentView.layer.cornerRadius = 10
        self.contentView.layer.shadowColor = UIColor.black.cgColor
        self.contentView.layer.shadowOpacity = 0.5
        self.contentView.layer.shadowRadius = 8
        self.contentView.layer.shadowOffset = .init(width: 0, height: 8)
        self.contentView.clipsToBounds = false
        self.contentView.layer.masksToBounds = false

        self.clipsToBounds = false
        self.layer.masksToBounds = false
    }
}
