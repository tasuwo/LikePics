//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Smoothie
import UIKit

public class ClipCollectionViewCell: UICollectionViewCell {
    public enum ThumbnailOrder: String {
        case primary
        case secondary
        case tertiary
    }

    public enum Image {
        case loaded(UIImage)
        case loading
        case failedToLoad
        case noImage
    }

    public static var nib: UINib { UINib(nibName: "ClipCollectionViewCell", bundle: Bundle(for: Self.self)) }

    public static let secondaryStickingOutMargin: CGFloat = 20
    public static let tertiaryStickingOutMargin: CGFloat = 15
    public static let cornerRadius: CGFloat = 10

    public var identifier: String?
    public var onReuse: ((String?) -> Void)?
    public weak var invalidator: ThumbnailInvalidatable?
    public private(set) var visibleHiddenIcon: Bool = false
    public private(set) var isHiddenClip: Bool = false

    public var primaryImage: Image? {
        didSet { updateImageViewAppearance(primaryImage, .primary) }
    }

    public var secondaryImage: Image? {
        didSet { updateImageViewAppearance(secondaryImage, .secondary) }
    }

    public var tertiaryImage: Image? {
        didSet { updateImageViewAppearance(tertiaryImage, .tertiary) }
    }

    public var isLoading: Bool {
        guard let primaryImage = primaryImage,
              let secondaryImage = secondaryImage,
              let tertiaryImage = tertiaryImage
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

    public var isEditing: Bool = false {
        didSet {
            updateOverallOverlayView()
            // TODO:
            // setOverallImageViewHidden(!isEditing)
        }
    }

    override public var isSelected: Bool {
        didSet { updateOverallOverlayView() }
    }

    @IBOutlet var overallImageView: UIImageView!

    @IBOutlet public var primaryImageView: UIImageView!
    @IBOutlet public var secondaryImageView: UIImageView!
    @IBOutlet public var tertiaryImageView: UIImageView!

    @IBOutlet var overallOverlayView: UIView!
    @IBOutlet var secondaryImageOverlayView: UIView!
    @IBOutlet var tertiaryImageOverlayView: UIView!

    @IBOutlet var imagesContainerView: UIView!

    @IBOutlet var selectionMark: UIView!
    @IBOutlet var indicator: UIActivityIndicatorView!

    @IBOutlet var hiddenIcon: HiddenIconView!

    // MARK: - Lifecycle

    override public func prepareForReuse() {
        super.prepareForReuse()
        onReuse?(self.identifier)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        setupAppearance()
    }

    // MARK: - Methods

    // MARK: Setup Appearance

    static func setupAppearance(imageView: UIImageView) {
        imageView.layer.cornerRadius = Self.cornerRadius
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    private func setupAppearance() {
        ([
            primaryImageView,
            secondaryImageView,
            tertiaryImageView
        ] as [UIImageView]).forEach {
            $0.isHidden = true
            Self.setupAppearance(imageView: $0)
        }

        overallImageView.contentMode = .scaleAspectFill
        overallImageView.isHidden = true

        ([
            overallOverlayView,
            secondaryImageOverlayView,
            tertiaryImageOverlayView
        ] as [UIView]).forEach {
            $0.isHidden = true
            $0.layer.cornerRadius = Self.cornerRadius
        }

        indicator.hidesWhenStopped = true

        selectionMark.backgroundColor = .white
        selectionMark.layer.cornerRadius = selectionMark.bounds.width / 2.0

        clipsToBounds = true
        layer.cornerRadius = Self.cornerRadius
        layer.masksToBounds = true

        updateOverallOverlayView()
    }

    // MARK: Set Appearance

    public func resetContent() {
        ([
            overallImageView,
            primaryImageView,
            secondaryImageView,
            tertiaryImageView
        ] as [UIImageView]).forEach {
            $0.image = nil
        }
        primaryImage = .loading
        secondaryImage = .loading
        tertiaryImage = .loading
    }

    public func setHiddenIconVisibility(_ isVisible: Bool, animated: Bool) {
        visibleHiddenIcon = isVisible
        updateHiddenIconAppearance(animated: animated)
    }

    public func setClipHiding(_ isHiding: Bool, animated: Bool) {
        isHiddenClip = isHiding
        updateHiddenIconAppearance(animated: animated)
    }

    private func setOverallImageViewHidden(_ isHidden: Bool) {
        overallImageView.isHidden = isHidden
        primaryImageView.isHidden = !isHidden
        secondaryImageView.isHidden = !isHidden
        tertiaryImageView.isHidden = !isHidden
        secondaryImageOverlayView.isHidden = !isHidden
        tertiaryImageOverlayView.isHidden = !isHidden
    }

    // MARK: Update Appearance

    private func updateOverallOverlayView() {
        overallOverlayView.isHidden = !((isSelected && isEditing) || isLoading)
        selectionMark.isHidden = !(isEditing && !isLoading)

        if isLoading {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
    }

    private func updateHiddenIconAppearance(animated: Bool) {
        if visibleHiddenIcon {
            hiddenIcon.setHiding(!isHiddenClip, animated: animated)
        } else {
            hiddenIcon.setHiding(true, animated: animated)
        }
    }

    private func updateImageViewAppearance(_ image: Image?, _ order: ThumbnailOrder) {
        defer { updateOverallOverlayView() }

        guard let image = image else {
            return
        }

        let imageView = imageView(order)
        imageView.isHidden = !image.isLoaded

        imageView.removeAspectRatioConstraint()
        overlayView(order)?.isHidden = !image.isLoaded

        imageView.removeAspectRatioConstraint()
        guard case let .loaded(image) = image else {
            imageView.image = nil
            if order.isPrimary { overallImageView.image = nil }
            return
        }

        imageView.addAspectRatioConstraint(image: image)
        imageView.image = image
        if order.isPrimary { overallImageView.image = image }
    }

    // MARK: Resolve UI Element

    private func setImage(_ image: Image?, at order: ThumbnailOrder) {
        switch order {
        case .primary:
            primaryImage = image

        case .secondary:
            secondaryImage = image

        case .tertiary:
            tertiaryImage = image
        }
    }

    private func imageView(_ order: ThumbnailOrder) -> UIImageView {
        switch order {
        case .primary:
            return primaryImageView

        case .secondary:
            return secondaryImageView

        case .tertiary:
            return tertiaryImageView
        }
    }

    private func overlayView(_ order: ThumbnailOrder) -> UIView? {
        switch order {
        case .primary:
            return nil

        case .secondary:
            return secondaryImageOverlayView

        case .tertiary:
            return tertiaryImageOverlayView
        }
    }
}

extension ClipCollectionViewCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[.clipThumbnailOrder] as? String,
                  let order = ThumbnailOrder(rawValue: value) else { return }
            self.setImage(.loading, at: order)
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[.clipThumbnailOrder] as? String,
                  let order = ThumbnailOrder(rawValue: value) else { return }
            self.setImage(.loaded(image), at: order)

            let displayScale = self.traitCollection.displayScale
            let originalSize = request.userInfo?[.originalImageSize] as? CGSize
            if self.shouldInvalidate(thumbnail: image, originalImageSize: originalSize, displayScale: displayScale) {
                self.invalidator?.invalidateCache(having: request.config.cacheKey)
            }
        }
    }

    public func didFailedToLoad(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[.clipThumbnailOrder] as? String,
                  let order = ThumbnailOrder(rawValue: value) else { return }
            self.setImage(.failedToLoad, at: order)
        }
    }
}

extension ClipCollectionViewCell: ClipPreviewPresentingCell {
    // MARK: - ClipPreviewPresentingCell

    public func animatingImageView(at index: Int) -> UIImageView? {
        switch index {
        case 1:
            return primaryImageView

        case 2:
            return secondaryImageView

        case 3:
            return tertiaryImageView

        default:
            return nil
        }
    }
}

extension ClipCollectionViewCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        // Note: frame.height は不定なので、計算に利用しない
        if let originalSize = originalPixelSize {
            if originalSize.width < originalSize.height {
                return .init(width: frame.width,
                             height: frame.width * (originalSize.height / originalSize.width))
            } else {
                return .init(width: frame.width * (originalSize.width / originalSize.height),
                             height: frame.width)
            }
        } else {
            return frame.size
        }
    }
}

private extension ClipCollectionViewCell.ThumbnailOrder {
    var isPrimary: Bool {
        return self == .primary
    }
}

private extension ClipCollectionViewCell.Image {
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
