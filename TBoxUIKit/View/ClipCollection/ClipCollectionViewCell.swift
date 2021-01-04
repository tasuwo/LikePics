//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class ClipCollectionViewCell: UICollectionViewCell {
    public static let ThumbnailLoadingUserInfoKey = "TBoxUIKit.ClipCollectionViewCell.ThumbnailLoadingUserInfoKey"

    public enum ThumbnailLoadingUserInfoValue: String {
        case primary
        case secondary
        case tertiary
    }

    public enum Image {
        case loaded(UIImage)
        case loading
        case failedToLoad
        case noImage

        var isLoaded: Bool {
            switch self {
            case .loaded:
                return true

            default:
                return false
            }
        }

        var isLoading: Bool {
            switch self {
            // NOTE: failedToLoad は、iCloud同期前でデータが読めていない可能性を考慮し、ロード中とする
            case .loading, .failedToLoad:
                return true

            default:
                return false
            }
        }
    }

    public static var nib: UINib {
        return UINib(nibName: "ClipCollectionViewCell", bundle: Bundle(for: Self.self))
    }

    public static let secondaryStickingOutMargin: CGFloat = 20
    public static let tertiaryStickingOutMargin: CGFloat = 15

    static let cornerRadius: CGFloat = 10

    public var identifier: String?

    public var primaryImage: Image? {
        didSet {
            defer { self.updateOverallOverlayView() }

            // nil が代入されることはない想定
            guard let primaryImage = self.primaryImage else { return }

            self.primaryImageView.isHidden = !primaryImage.isLoaded

            self.primaryImageView.removeAspectRatioConstraint()
            guard case let .loaded(image) = primaryImage else {
                self.primaryImageView.image = nil
                return
            }

            self.primaryImageView.addAspectRatioConstraint(image: image)
            self.primaryImageView.image = image
        }
    }

    public var secondaryImage: Image? {
        didSet {
            defer { self.updateOverallOverlayView() }

            // nil が代入されることはない想定
            guard let secondaryImage = self.secondaryImage else { return }

            self.secondaryImageView.isHidden = !secondaryImage.isLoaded
            self.secondaryImageOverlayView.isHidden = !secondaryImage.isLoaded

            self.secondaryImageView.removeAspectRatioConstraint()
            guard case let .loaded(image) = secondaryImage else {
                self.secondaryImageView.image = nil
                return
            }

            self.secondaryImageView.addAspectRatioConstraint(image: image)
            self.secondaryImageView.image = image
        }
    }

    public var tertiaryImage: Image? {
        didSet {
            defer { self.updateOverallOverlayView() }

            // nil が代入されることはない想定
            guard let tertiaryImage = self.tertiaryImage else { return }

            self.tertiaryImageView.isHidden = !tertiaryImage.isLoaded
            self.tertiaryImageOverlayView.isHidden = !tertiaryImage.isLoaded

            self.tertiaryImageView.removeAspectRatioConstraint()
            guard case let .loaded(image) = tertiaryImage else {
                self.tertiaryImageView.image = nil
                return
            }

            self.tertiaryImageView.addAspectRatioConstraint(image: image)
            self.tertiaryImageView.image = image
        }
    }

    public var visibleSelectedMark: Bool = false {
        didSet {
            self.updateOverallOverlayView()
        }
    }

    public var isLoading: Bool {
        guard let primaryImage = self.primaryImage,
            let secondaryImage = self.secondaryImage,
            let tertiaryImage = self.tertiaryImage
        else {
            return true
        }
        return primaryImage.isLoading
            || secondaryImage.isLoading
            || tertiaryImage.isLoading
            // NOTE: iCloud同期はEntity単位で行われ、Relationが欠けている可能性がある
            //       その場合、primaryImage が nil になり得る
            //       primaryImage が nil の Clip はあり得ないため、ロード中状態とする
            // NOTE: secondary, tertiary が未ロードのケースは、未ロードなのか？本当に存在しないのか？
            //       判定できないため、考慮しない
            || !primaryImage.isLoaded
    }

    public var onReuse: ((String?) -> Void)?

    override public var isSelected: Bool {
        didSet {
            self.updateOverallOverlayView()
        }
    }

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
            self.tertiaryImageOverlayView,
            self.overallOverlayView
        ]
    }

    @IBOutlet public var primaryImageView: UIImageView!
    @IBOutlet public var secondaryImageView: UIImageView!
    @IBOutlet public var tertiaryImageView: UIImageView!

    @IBOutlet var secondaryImageOverlayView: UIView!
    @IBOutlet var tertiaryImageOverlayView: UIView!

    @IBOutlet var imagesContainerView: UIView!

    @IBOutlet var overallOverlayView: UIView!
    @IBOutlet var selectionMark: UIView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    // MRAK: - Lifecycle

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.onReuse?(self.identifier)
    }

    // MARK: - Methods

    static func setupAppearance(imageView: UIImageView) {
        imageView.layer.cornerRadius = Self.cornerRadius
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    static func setupAppearance(shadowView: UIView) {
        shadowView.layer.cornerRadius = Self.cornerRadius
        shadowView.clipsToBounds = false
        shadowView.layer.masksToBounds = false
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.setupAppearance()
    }

    private func setupAppearance() {
        self.imageViews.forEach {
            $0.isHidden = true
            Self.setupAppearance(imageView: $0)
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

        self.indicator.hidesWhenStopped = true

        self.selectionMark.backgroundColor = .white
        self.selectionMark.layer.cornerRadius = self.selectionMark.bounds.width / 2.0

        self.updateOverallOverlayView()
    }

    private func updateOverallOverlayView() {
        self.overallOverlayView.isHidden = !((self.isSelected && self.visibleSelectedMark) || self.isLoading)
        self.selectionMark.isHidden = !(self.visibleSelectedMark && !self.isLoading)

        if self.isLoading {
            self.indicator.startAnimating()
        } else {
            self.indicator.stopAnimating()
        }
    }
}

extension ClipCollectionViewCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[Self.ThumbnailLoadingUserInfoKey] as? String,
                let kind = ThumbnailLoadingUserInfoValue(rawValue: value) else { return }
            switch kind {
            case .primary:
                self.primaryImage = .loading

            case .secondary:
                self.secondaryImage = .loading

            case .tertiary:
                self.tertiaryImage = .loading
            }
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[Self.ThumbnailLoadingUserInfoKey] as? String,
                let kind = ThumbnailLoadingUserInfoValue(rawValue: value) else { return }
            switch kind {
            case .primary:
                self.primaryImage = .loaded(image)

            case .secondary:
                self.secondaryImage = .loaded(image)

            case .tertiary:
                self.tertiaryImage = .loaded(image)
            }
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[Self.ThumbnailLoadingUserInfoKey] as? String,
                let kind = ThumbnailLoadingUserInfoValue(rawValue: value) else { return }
            switch kind {
            case .primary:
                self.primaryImage = .failedToLoad

            case .secondary:
                self.secondaryImage = .failedToLoad

            case .tertiary:
                self.tertiaryImage = .failedToLoad
            }
        }
    }
}
