//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipCollectionViewCell: UICollectionViewCell {
    public enum ThumbnailOrder: String {
        case primary
        case secondary
        case tertiary
    }

    public static var nib: UINib { UINib(nibName: "ClipCollectionViewCell", bundle: Bundle(for: Self.self)) }

    public static let secondaryStickingOutMargin: CGFloat = 20
    public static let tertiaryStickingOutMargin: CGFloat = 15
    public static let cornerRadius: CGFloat = 16

    public var identifier: String?
    public var onReuse: ((String?) -> Void)?
    public weak var invalidator: ThumbnailInvalidatable?

    public var sizeDescription: ClipCollectionViewCellSizeDescription? {
        didSet {
            updateThumbnailConstraints()
            updateOverallOverlayView()
        }
    }

    public var isEditing = false {
        didSet {
            updateOverallOverlayView()
        }
    }

    override public var isSelected: Bool {
        didSet {
            updateOverallOverlayView()
        }
    }

    public var isLoading: Bool {
        guard let description = sizeDescription else { return false }

        // NOTE: iCloud同期はEntity単位で行われ、Relationが欠けている可能性がある
        //       その場合、primaryImage が nil になり得る
        //       primaryImage が nil の Clip はあり得ないため、ロード中状態とする
        // NOTE: secondary, tertiary が未ロードのケースは、未ロードなのか？本当に存在しないのか？
        //       判定できないため、考慮しない
        if primaryThumbnailView.isLoading {
            return true
        }

        if description.containsSecondaryThumbnailSize, secondaryThumbnailView.isLoading {
            return true
        }

        if description.containsTertiaryThumbnailSize, tertiaryThumbnailView.isLoading {
            return true
        }

        return false
    }

    public private(set) var isSingleThumbnail = false
    public private(set) var visibleHiddenIcon = false
    public private(set) var isHiddenClip = false

    @IBOutlet var primaryThumbnailView: ClipCollectionThumbnailView!
    @IBOutlet var secondaryThumbnailView: ClipCollectionThumbnailView!
    @IBOutlet var tertiaryThumbnailView: ClipCollectionThumbnailView!

    @IBOutlet var secondaryThumbnailDisplayConstraint: NSLayoutConstraint!
    @IBOutlet var tertiaryThumbnailDisplayConstraint: NSLayoutConstraint!

    @IBOutlet var hiddenIconBottomToThumbnailConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenIconTrailingToThumbnailConstraint: NSLayoutConstraint!

    @IBOutlet var overallThumbnailView: UIImageView!

    @IBOutlet var overallOverlayView: UIView!

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
        imageView.layer.cornerCurve = .continuous
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
    }

    private func setupAppearance() {
        overallThumbnailView.alpha = 0
        overallOverlayView.isHidden = true

        indicator.hidesWhenStopped = true

        selectionMark.backgroundColor = .white
        selectionMark.layer.cornerRadius = selectionMark.bounds.width / 2.0

        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = Self.cornerRadius
        layer.cornerCurve = .continuous

        updateOverallOverlayView()
    }

    // MARK: Set Appearance

    public func resetContent() {
        sizeDescription = nil
        overallThumbnailView.image = nil
        primaryThumbnailView.thumbnail = nil
        secondaryThumbnailView.thumbnail = nil
        tertiaryThumbnailView.thumbnail = nil
    }

    public func setHiddenIconVisibility(_ isVisible: Bool, animated: Bool) {
        visibleHiddenIcon = isVisible
        updateHiddenIconAppearance(animated: animated)
    }

    public func setClipHiding(_ isHiding: Bool, animated: Bool) {
        isHiddenClip = isHiding
        updateHiddenIconAppearance(animated: animated)
    }

    public func setThumbnailType(toSingle: Bool) {
        isSingleThumbnail = toSingle
        overallThumbnailView.alpha = toSingle ? 1 : 0
        primaryThumbnailView.alpha = toSingle ? 0 : 1
        secondaryThumbnailView.alpha = toSingle ? 0 : 1
        tertiaryThumbnailView.alpha = toSingle ? 0 : 1
        hiddenIconBottomToThumbnailConstraint.isActive = !toSingle
        hiddenIconTrailingToThumbnailConstraint.isActive = !toSingle
    }

    public func setThumbnailTypeWithAnimationBlocks(toSingle: Bool) -> (() -> Void) {
        guard !isLoading else {
            setThumbnailType(toSingle: toSingle)
            return {}
        }

        isSingleThumbnail = toSingle

        let animatingImageView = UIImageView(image: primaryThumbnailView.imageView.image)
        animatingImageView.contentMode = .scaleAspectFill
        animatingImageView.clipsToBounds = true
        animatingImageView.layer.cornerRadius = Self.cornerRadius
        animatingImageView.layer.cornerCurve = .continuous
        animatingImageView.frame = toSingle ? primaryThumbnailView.frame : overallThumbnailView.frame
        addSubview(animatingImageView)

        overallThumbnailView.alpha = 0
        primaryThumbnailView.alpha = 0
        hiddenIcon.alpha = 0

        hiddenIconBottomToThumbnailConstraint.isActive = !toSingle
        hiddenIconTrailingToThumbnailConstraint.isActive = !toSingle

        return {
            UIView.animate(withDuration: 0.25) {
                animatingImageView.frame = toSingle ? self.overallThumbnailView.frame : self.primaryThumbnailView.frame
                self.secondaryThumbnailView.alpha = toSingle ? 0 : 1
                self.tertiaryThumbnailView.alpha = toSingle ? 0 : 1
            } completion: { _ in
                self.overallThumbnailView.alpha = toSingle ? 1 : 0
                self.primaryThumbnailView.alpha = toSingle ? 0 : 1
                self.secondaryThumbnailView.alpha = toSingle ? 0 : 1
                self.tertiaryThumbnailView.alpha = toSingle ? 0 : 1
                animatingImageView.removeFromSuperview()
            }

            UIView.animate(withDuration: 0.15, delay: 0.25, options: [], animations: {
                self.hiddenIcon.alpha = 1
            }, completion: nil)
        }
    }

    // MARK: Update Appearance

    private func updateThumbnailConstraints() {
        guard let description = sizeDescription else {
            primaryThumbnailView.thumbnailSize = .init(width: 1, height: 1)
            secondaryThumbnailView.thumbnailSize = nil
            tertiaryThumbnailView.thumbnailSize = nil
            secondaryThumbnailDisplayConstraint.isActive = false
            tertiaryThumbnailDisplayConstraint.isActive = false
            return
        }

        primaryThumbnailView.thumbnailSize = description.primaryThumbnailSize
        secondaryThumbnailView.thumbnailSize = description.secondaryThumbnailSize
        tertiaryThumbnailView.thumbnailSize = description.tertiaryThumbnailSize

        secondaryThumbnailDisplayConstraint.isActive = description.containsSecondaryThumbnailSize
        tertiaryThumbnailDisplayConstraint.isActive = description.containsTertiaryThumbnailSize
    }

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

    // MARK: Resolve UI Element

    private func setResult(_ result: ClipCollectionThumbnailView.ThumbnailLoadResult, at order: ThumbnailOrder) {
        switch order {
        case .primary:
            overallThumbnailView.image = result.image
            primaryThumbnailView.thumbnail = result

        case .secondary:
            secondaryThumbnailView.thumbnail = result

        case .tertiary:
            tertiaryThumbnailView.thumbnail = result
        }
        updateOverallOverlayView()
    }
}

extension ClipCollectionViewCell: ThumbnailLoadObserver {
    // MARK: - ThumbnailLoadObserver

    public func didStartLoading(_ request: ThumbnailRequest) {
        DispatchQueue.main.async {
            self.updateOverallOverlayView()
        }
    }

    public func didSuccessToLoad(_ request: ThumbnailRequest, image: UIImage) {
        DispatchQueue.main.async {
            guard self.identifier == request.requestId else { return }
            guard let value = request.userInfo?[.clipThumbnailOrder] as? String,
                  let order = ThumbnailOrder(rawValue: value) else { return }
            self.setResult(.success(image), at: order)

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
            self.setResult(.failure, at: order)
        }
    }
}

extension ClipCollectionViewCell: ClipPreviewPresentingCell {
    // MARK: - ClipPreviewPresentingCell

    public func primaryThumbnailImageView() -> UIImageView {
        return isSingleThumbnail ? overallThumbnailView : primaryThumbnailView.imageView
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
