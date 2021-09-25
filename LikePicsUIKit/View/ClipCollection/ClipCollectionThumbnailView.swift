//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

@IBDesignable
public class ClipCollectionThumbnailView: UIView {
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
            imageView.image = thumbnail?.image
            updateLoadingState()
        }
    }

    var isLoading: Bool {
        // failure は、iCloud同期前でデータが読めていない可能性を考慮し、ロード中とする
        return thumbnail == nil || thumbnail == .failure
    }

    @IBInspectable var isOverlayHidden: Bool = false {
        didSet { updateOverlayAppearance() }
    }

    let imageView = UIImageView()
    private let overlayView = UIView()

    public weak var pipeline: Pipeline?

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        configureViewHierarchy()

        updateAspectRatioConstraint()
        updateLoadingState()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configureViewHierarchy()

        updateAspectRatioConstraint()
        updateLoadingState()
    }
}

// MARK: - Configure

extension ClipCollectionThumbnailView {
    private func configureViewHierarchy() {
        backgroundColor = .clear

        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate(imageView.constraints(fittingIn: self))

        addSubview(overlayView)
        overlayView.isHidden = true
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.backgroundColor = .black.withAlphaComponent(0.4)
        NSLayoutConstraint.activate(overlayView.constraints(fittingIn: self))

        clipsToBounds = true
        layer.masksToBounds = true
        layer.cornerRadius = Self.thumbnailCornerRadius
    }
}

// MARK: - Update

extension ClipCollectionThumbnailView {
    private func updateAspectRatioConstraint() {
        guard let size = thumbnailSize else {
            imageView.removeAspectRatioConstraint()
            return
        }
        imageView.addAspectRatioConstraint(size: size)
    }

    private func updateOverlayAppearance() {
        overlayView.isHidden = isOverlayHidden || isLoading
    }

    private func updateLoadingState() {
        imageView.isHidden = isLoading
        updateOverlayAppearance()
    }
}

extension ClipCollectionThumbnailView: ImageDisplayable {
    public func smt_willLoad(userInfo: [AnyHashable: Any]?) {
        thumbnail = .none
        backgroundColor = Asset.Color.secondaryBackground.color
    }

    public func smt_display(_ image: UIImage?, userInfo: [AnyHashable: Any]?) {
        DispatchQueue.main.async {
            self.backgroundColor = .clear

            guard let image = image else {
                self.thumbnail = .failure
                return
            }

            self.thumbnail = .success(image)

            if let originalSize = userInfo?["originalSize"] as? CGSize,
               let cacheKey = userInfo?["cacheKey"] as? String
            {
                let displayScale = self.traitCollection.displayScale
                if self.shouldInvalidate(thumbnail: image, originalImageSize: originalSize, displayScale: displayScale) {
                    self.pipeline?.config.diskCache?.remove(forKey: cacheKey)
                    self.pipeline?.config.memoryCache.remove(forKey: cacheKey)
                }
            }
        }
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
