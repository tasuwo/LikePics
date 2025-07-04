//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class ClipCollectionViewCell: UICollectionViewCell {
    public static var nib: UINib { UINib(nibName: "ClipCollectionViewCell", bundle: Bundle.module) }

    public static let secondaryStickingOutMargin: CGFloat = 20
    public static let tertiaryStickingOutMargin: CGFloat = 15
    public static let cornerRadius: CGFloat = 16

    public var sizeDescription: ClipCollectionViewCellSizeDescription? {
        didSet {
            updateThumbnailConstraints()
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

    @IBOutlet public var singleThumbnailView: ClipCollectionSingleThumbnailView!

    @IBOutlet public var primaryThumbnailView: ClipCollectionThumbnailView!
    @IBOutlet public var secondaryThumbnailView: ClipCollectionThumbnailView!
    @IBOutlet public var tertiaryThumbnailView: ClipCollectionThumbnailView!

    @IBOutlet var hiddenIconBottomToThumbnailConstraint: NSLayoutConstraint!
    @IBOutlet var hiddenIconTrailingToThumbnailConstraint: NSLayoutConstraint!

    @IBOutlet var overallOverlayView: UIView!

    @IBOutlet var selectionMark: UIView!

    @IBOutlet var hiddenIcon: HiddenIconView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            setupAppearance()
        }
    }

    // MARK: - Methods

    // MARK: Setup Appearance

    static func setupAppearance(imageView: UIImageView) {
        imageView.layer.cornerRadius = cornerRadius
        imageView.layer.cornerCurve = .continuous
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
    }

    private func setupAppearance() {
        singleThumbnailView.alpha = 0
        overallOverlayView.isHidden = true

        secondaryThumbnailView.isOverlayHidden = false
        secondaryThumbnailView.overlayOpacity = 0.4
        tertiaryThumbnailView.isOverlayHidden = false
        tertiaryThumbnailView.overlayOpacity = 0.5

        selectionMark.backgroundColor = .white
        selectionMark.layer.cornerRadius = selectionMark.bounds.width / 2.0

        layer.cornerRadius = Self.cornerRadius
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        updateOverallOverlayView()
    }

    // MARK: Set Appearance

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
        singleThumbnailView.alpha = toSingle ? 1 : 0
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

        let animatingImageView = UIImageView(image: primaryThumbnailView.image)
        animatingImageView.contentMode = .scaleAspectFill
        animatingImageView.clipsToBounds = true
        animatingImageView.layer.cornerRadius = Self.cornerRadius
        animatingImageView.layer.cornerCurve = .continuous
        animatingImageView.frame = toSingle ? primaryThumbnailView.frame : singleThumbnailView.frame
        addSubview(animatingImageView)

        singleThumbnailView.alpha = 0
        primaryThumbnailView.alpha = 0
        hiddenIcon.alpha = 0

        hiddenIconBottomToThumbnailConstraint.isActive = !toSingle
        hiddenIconTrailingToThumbnailConstraint.isActive = !toSingle

        return {
            UIView.likepics_animate(withDuration: 0.25) {
                animatingImageView.frame = toSingle ? self.singleThumbnailView.frame : self.primaryThumbnailView.frame
                self.secondaryThumbnailView.alpha = toSingle ? 0 : 1
                self.tertiaryThumbnailView.alpha = toSingle ? 0 : 1
            } completion: { _ in
                self.singleThumbnailView.alpha = toSingle ? 1 : 0
                self.primaryThumbnailView.alpha = toSingle ? 0 : 1
                self.secondaryThumbnailView.alpha = toSingle ? 0 : 1
                self.tertiaryThumbnailView.alpha = toSingle ? 0 : 1
                animatingImageView.removeFromSuperview()
            }

            UIView.likepics_animate(
                withDuration: 0.15,
                delay: 0.25,
                options: [],
                animations: {
                    self.hiddenIcon.alpha = 1
                },
                completion: nil
            )
        }
    }

    // MARK: Update Appearance

    private func updateThumbnailConstraints() {
        guard let description = sizeDescription else { return }

        primaryThumbnailView.thumbnailSize = description.primaryThumbnailSize
        secondaryThumbnailView.thumbnailSize = description.secondaryThumbnailSize
        tertiaryThumbnailView.thumbnailSize = description.tertiaryThumbnailSize

        secondaryThumbnailView.isHidden = !description.containsSecondaryThumbnailSize
        tertiaryThumbnailView.isHidden = !description.containsTertiaryThumbnailSize
    }

    private func updateOverallOverlayView() {
        overallOverlayView.isHidden = !(isSelected && isEditing)
    }

    private func updateHiddenIconAppearance(animated: Bool) {
        if visibleHiddenIcon {
            hiddenIcon.setHiding(!isHiddenClip, animated: animated)
        } else {
            hiddenIcon.setHiding(true, animated: animated)
        }
    }
}

extension ClipCollectionViewCell: ClipPreviewPresentableCell {
    // MARK: - ClipPreviewPresentableCell

    public func thumbnail() -> UIImageView {
        return isSingleThumbnail ? singleThumbnailView : primaryThumbnailView
    }
}
