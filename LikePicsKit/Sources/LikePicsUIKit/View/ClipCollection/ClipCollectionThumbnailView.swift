//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

@IBDesignable
public class ClipCollectionThumbnailView: UIImageView {
    enum ThumbnailLoadResult: Equatable {
        case success(UIImage)
        case failure

        var image: UIImage? {
            switch self {
            case let .success(image):
                return image

            default:
                return nil
            }
        }
    }

    static let thumbnailCornerRadius: CGFloat = 10

    var thumbnailSize: CGSize? {
        didSet { updateAspectRatioConstraint() }
    }

    var thumbnail: ThumbnailLoadResult? {
        didSet {
            image = thumbnail?.image
        }
    }

    var isLoading: Bool {
        // failure は、iCloud同期前でデータが読めていない可能性を考慮し、ロード中とする
        return thumbnail == nil || thumbnail == .failure
    }

    @IBInspectable var isOverlayHidden: Bool = false {
        didSet {
            overlayLayer.isHidden = isOverlayHidden
        }
    }

    @IBInspectable var overlayOpacity: CGFloat = 0.4 {
        didSet {
            overlayLayer.backgroundColor = UIColor.black.withAlphaComponent(overlayOpacity).cgColor
        }
    }

    private let overlayLayer = CALayer()

    public weak var processingQueue: ImageProcessingQueue?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureViewHierarchy()

        updateAspectRatioConstraint()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configureViewHierarchy()

        updateAspectRatioConstraint()
    }

    // MARK: - View Life-Cycle Methods

    override public func layoutSubviews() {
        super.layoutSubviews()
        overlayLayer.frame = bounds
    }
}

// MARK: - Configure

extension ClipCollectionThumbnailView {
    private func configureViewHierarchy() {
        backgroundColor = .clear

        overlayLayer.frame = bounds
        layer.addSublayer(overlayLayer)
        overlayLayer.isHidden = true
        overlayLayer.backgroundColor = UIColor.black.withAlphaComponent(overlayOpacity).cgColor

        layer.masksToBounds = true
        layer.cornerRadius = Self.thumbnailCornerRadius
        layer.cornerCurve = .continuous
    }
}

// MARK: - Update

extension ClipCollectionThumbnailView {
    private func updateAspectRatioConstraint() {
        guard let size = thumbnailSize else {
            removeAspectRatioConstraint()
            return
        }
        addAspectRatioConstraint(size: size)
    }
}

// MARK: - ImageDisplayable

public extension ClipCollectionThumbnailView {
    override func smt_display(_ image: UIImage?) {
        guard let image = image else {
            self.thumbnail = .none
            self.overlayLayer.opacity = 0
            self.backgroundColor = Asset.Color.secondaryBackground.color
            return
        }

        self.thumbnail = .success(image)
        self.overlayLayer.opacity = 1
        self.backgroundColor = .clear
    }
}

extension ClipCollectionThumbnailView: ThumbnailPresentable {
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
