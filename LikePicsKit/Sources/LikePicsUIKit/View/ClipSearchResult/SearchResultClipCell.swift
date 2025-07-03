//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Smoothie
import UIKit

public class SearchResultClipCell: UICollectionViewCell {
    public static let imageCornerRadius: CGFloat = 12

    public static var nib: UINib {
        return UINib(nibName: "SearchResultClipCell", bundle: Bundle.module)
    }

    @IBOutlet public var imageView: UIImageView!

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            self.setupAppearance()
        }
    }

    // MARK: - Methods

    private func setupAppearance() {
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Self.imageCornerRadius
        self.layer.cornerCurve = .continuous
    }
}

// MARK: - ImageDisplayable

extension SearchResultClipCell: ImageDisplayable {
    public func smt_display(_ image: UIImage?) {
        guard let image = image else {
            self.imageView.image = nil
            self.backgroundColor = Asset.Color.secondaryBackground.color
            return
        }

        self.backgroundColor = .clear
        UIView.transition(
            with: self.imageView,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: { [weak self] in self?.imageView.image = image },
            completion: nil
        )
    }
}

extension SearchResultClipCell: ClipPreviewPresentableCell {
    // MARK: - ClipPreviewPresentableCell

    public func thumbnail() -> UIImageView { imageView }
}

extension SearchResultClipCell: ThumbnailPresentable {
    // MARK: - ThumbnailPresentable

    public func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize {
        if let originalSize = originalPixelSize {
            if originalSize.width < originalSize.height {
                return .init(
                    width: frame.width,
                    height: frame.width * (originalSize.height / originalSize.width)
                )
            } else {
                return .init(
                    width: frame.height * (originalSize.width / originalSize.height),
                    height: frame.height
                )
            }
        } else {
            return frame.size
        }
    }
}
